## =========================== ##

# Martin Zumaya Hernandez
# Enero 2015
# Implementacion Flocks en Julia
# Aproximacion de objetos

## =========================== ##

# Definicion del tipo Bird

type Bird
  pos::Array{Float64,1}
  vel::Array{Float64,1}
  inputs::Array{Int64,1}
end

nzrange(S::SparseMatrixCSC, col::Integer) = S.colptr[col]:(S.colptr[col+1]-1)

rngNoise = MersenneTwister() # ruido
rngInit = MersenneTwister() # condiciones iniciales

seedNoise = convert(Uint32,666)
seedInit = convert(Uint32,123)

srand(rngNoise,seedNoise)
srand(rngInit,seedInit)

## =========================== ## ## =========================== ##

# Regresa Vector aleatorio entre -L:L

function RandVec(L::Float64)

  return [-L + rand(rngInit)*2.0*L, -L + rand(rngInit)*2.0*L]
end

function RandNum(L::Float64)

  return -L + rand(rngInit)*2.0*L
end

function RandInt(A::Int64,B::Int64)
  return convert(Int64,floor(A + rand(rngInit)*(B-A)))
end

function setNoise(N::Int64)
  noise = convert(Array{Float64,1},[rand(rngNoise) for i = 1:N])
  # broadcast!(x -> -1.0*pi + 2.0*x*pi, noise, noise)
  broadcast!(x -> -pi + 2.0*x*pi, noise, noise)
  return noise
end

## =========================== ## ## =========================== ##

# Regresa angulo entre 2 vectores

function AngVecs(v1::Array{Float64,1},v2::Array{Float64,1})
  a1 = atan2(v1[2],v1[1])
  a2 = atan2(v2[2],v2[1])
  return a2-a1
end

## =========================== ## ## =========================== ##

# Inicializa posiciones y velocidades
# Velocidades normallizadas a v0

function InitParts(path::String,N::Int64,parts::Array{Bird,1})

  pos    = readdlm("$path/trays.txt",'\t',Float64)
  vel    = readdlm("$path/vels.txt",'\t',Float64)
  intNet = readdlm("$path/intNet.txt",',',Int64)

  # for i = 0:convert(Int64,size(pos,2)*0.5-1)
  for i = 0:N-1
    parts[i+1] = Bird(reshape(pos[1,2i+1:2i+2],2), reshape(vel[1,2i+1:2i+2],2), reshape(intNet[i+1,:],2))
  end
end

function InitParts(parts::Array{Bird,1},N::Int64,L::Float64,v0::Float64,k::Int64)
  for i = 1:N
    vel = RandVec(1.0)
    parts[i] = Bird(RandVec(L), scale!(vel,v0/norm(vel)), Inputs(k,N,i))
  end
end

## =========================== ## ## =========================== ##

# Actualiza posiciones
function UpdatePos!(parts::Array{Bird,1},dt::Float64)
	for bird = parts
  	broadcast!(+,bird.pos,bird.pos,scale(bird.vel,dt))
  	# bird.pos += scale(bird.vel,dt)
	end
end

## =========================== ## ## =========================== ##

#Construye red aleatoria de conectividad k

function Inputs(k::Int64,N::Int64,tag::Int64)

  ins = Array(Int64,k)

  for j = 1:k

    switch = true

    while switch
      # print("in ")
      # s = rand(1:N)
      s = RandInt(1,N)

      if s != tag
        # println("$s,$tag")
        ins[j] = s
        switch = false
        # print("out ")
      end
    end
  end
  return ins
end

## =========================== ## ## =========================== ##

function SetLR(k::Int64,N::Int64,X::SparseMatrixCSC{Float64,Int64})

    for i = 1:size(X,1) , j = 1:k
        switch = true
          while switch
              s = rand(1:N)
              if s != i
                  X[i,s] = 1
                  #X[i,s] = X[s,i] = 1
                  switch = false
              end
          end
    end
end

## =========================== ## ## =========================== ##

#calcula distancias y adjacencia local

function SetSR(r0::Float64,dists::Array{Float64,2},parts::Array{Bird,1})

  N = size(parts,1)

  I = Int64[]
  J = Int64[]

  for i = 1:N , j = i+1:N

    d = norm(parts[i].pos - parts[j].pos)

    dists[i,j] = dists[j,i] = d

    if d <= r0
      push!(I,i)
      push!(J,j)
    end
  end

  return sparse(vcat(I,J),vcat(J,I),ones(2*size(I,1)))
end

## =========================== ## ## =========================== ##

#Calcula las direcciones de la velocidad promedio de cada vecindad
# A -> Matriz de Adjacencia

function GetAngs(parts::Array{Bird,1}, A::SparseMatrixCSC{Float64,Int64})

  # Arreglo de angulos, 1 por particula
  angs = zeros(Float64,size(parts,1))

  neigh = A.rowval

  for i = 1:size(A,2) #itera sobre las particulas con vecindad

    k = 0.0 # para guardar numero de parts en la vecindad

    # v_prom = parts[i].vel
    v_prom = zeros(Float64,2)

    for j = nzrange(A,i)

      # tal = neigh[j]
      # println("part : $i ; vecina : $tal")

      v_prom += parts[neigh[j]].vel

      k += 1.0

    end

    # println("k = $k")
    if k > 0
      scale!(v_prom,1.0/k)
      angs[i] = AngVecs(parts[i].vel,v_prom) #agrega el angulo al arreglo
    end

  end

  return angs
end

## =========================== ## ## =========================== ##

# Angulos de entradas en la red de interaccion

function GetAngsIN(parts::Array{Bird,1})

	k = size(parts[1].inputs,1) # conectividad
  N = size(parts,1)

  # Arreglo de angulos, 1 por particula
  # angs = Array(Float64,N)
  angs = zeros(Float64,N)

  # println(angs)

  if k>0

    for i = 1:N

      # v_prom = parts[i].vel
      v_prom = zeros(Float64,2)

      for j = parts[i].inputs
        v_prom += parts[j].vel
      end

      scale!(v_prom,1.0/k)
      angs[i] = AngVecs(parts[i].vel,v_prom) #agrega el angulo al arreglo

    end

  end

  return angs
end

## =========================== ## ## =========================== ##

#Rota vector 2D

function RotVec!(vec::Array{Float64,1},alpha::Float64)

  X = vec[1]*cos(alpha) - vec[2]*sin(alpha)
  Y = vec[1]*sin(alpha) + vec[2]*cos(alpha)

  vec[1] = X
  vec[2] = Y
end

## =========================== ## ## =========================== ##

function makeTurn!(rate::Float64, velPert::Array{Float64,1})
  ang = (0.5*pi)/rate
  RotVec!(velPert,ang)
end


## =========================== ## ## =========================== ##

#Actualiza velocidades

function UpdateVel!(parts::Array{Bird,1},SR::SparseMatrixCSC{Float64,Int64},
                    eta::Float64,w::Float64,ruido::Array{Float64,1})

    LOC = GetAngs(parts,SR) #Angulos inter corto
    IN = GetAngsIN(parts) #Angulos inter largo

    for i = 1:size(parts,1)

      # ang_rand = RandNum(1.0*pi)
      # ang_tot =  w * (IN[i]) + (1.0 - w) * (LOC[i]) + eta*ang_rand

      ang_tot =  w * (IN[i]) + (1.0 - w) * (LOC[i]) + eta*ruido[i]

      RotVec!(parts[i].vel,ang_tot)

    end
end

function UpdateVel!(parts::Array{Bird,1},SR::SparseMatrixCSC{Float64,Int64},eta::Float64,w::Float64,
                    ruido::Array{Float64,1},numPert::Int64,velPert::Array{Float64,1})

    LOC = GetAngs(parts,SR) #Angulos inter corto
    IN = GetAngsIN(parts) #Angulos inter largo

    for i = 1:size(parts,1)

      if i != numPert
        ang_tot =  w * (IN[i]) + (1.0 - w) * (LOC[i]) + eta*ruido[i]
        RotVec!(parts[i].vel,ang_tot)
      end

    end

    # parts[numPert].vel = velPert
    copy!(parts[numPert].vel, velPert)

end

## =========================== ## ## =========================== ##

#Actualiza todo

function Evoluciona(i::Int64, step::Int64, parts::Array{Bird,1},
                    eta::Float64,w::Float64, dists::Array{Float64,2})

  SR = SetSR(r0,dists,parts)

  UpdateVel!(parts,SR,eta,w,setNoise(size(parts,1)))
  UpdatePos!(parts,dt)

  if  i == 1 || i%step == 0
    println("t = $i writing")
    PrintTrays(i,parts)
    PrintVels(i,parts)
    PrintDist(i,dists)
  end

end

function Evoluciona(i::Int64, step::Int64, parts::Array{Bird,1},
                    eta::Float64,w::Float64, dists::Array{Float64,2},
                    partPert::Int64, velPert::Array{Float64,1},tau::Int64,turnRate::Float64)

  SR = SetSR(r0,dists,parts)

  if i==tau
    copy!(velPert,parts[partPert].vel)
    println("set Vel")
  end

  turn = convert(Int64,turnRate)

  if i >= tau && i <= tau + turn

    if i >= tau && i <= tau + turn
      RotVec!(velPert,ang)
    end

    UpdateVel!(parts,SR,eta,w,setNoise(size(parts,1)),partPert,velPert)


    # RotVec!(velPert,ang)

  end

  UpdateVel!(parts,SR,eta,w,setNoise(size(parts,1)))
  UpdatePos!(parts,dt)

  if  i == 1 || i%step == 0
    println("t = $i writing")
    PrintTrays(i,parts)
    PrintVels(i,parts)
    PrintDist(i,dists)
  end

end

## =========================== ## ## =========================== ##
