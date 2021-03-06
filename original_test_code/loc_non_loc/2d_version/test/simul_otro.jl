# Modelo movimiento colectivo
# Paralelo con SharedArrays

# @everywhere include("/Users/martinC3/GitRepos/CollectiveDynamics.jl/new/pl.jl") # osx (C3)
# @everywhere include("/Users/mzumaya/GitRepos/CollectiveDynamics.jl/new/pl.jl") # osx (C3)

@everywhere include("/home/martin/GitRepos/CollectiveDynamics.jl/new/pl.jl") # comadreja

####========================================####
####             PARAMETERS                 ####
####========================================####

param = Param()

dt = 1.0
l = 0.1

param.v0 = 1.0

param.r0 = param.v0 * dt / l
param.omega = 0.5 # peso interacciones

if length(ARGS) == 5

    #  Parametros de linea de comando

    param.N   = parse(Int64,   ARGS[1]);
    m_frac    = parse(Float64, ARGS[2]);
    param.eta = parse(Float64, ARGS[3]);
    rho       = parse(Float64, ARGS[4]);
    reps      = parse(Int64, ARGS[5]);

elseif length(ARGS) == 0

    # Valores por defecto de parametros

    println("Usando valores por defecto");

    param.N   = 1000
    m_frac    = 0.006
    param.eta = 0.15
    rho       = 10.0
    reps      = 5

elseif length(ARGS) > 0 && length(ARGS) < 5
    println("Faltan parametros")
    exit()
end

tot_links = param.N * (param.N - 1)
links     = m_frac * float(tot_links)

param.M = round(Int, links)
param.bound = sqrt( float(param.N) / rho)

path = "../DATA/data_n$(param.N)_eta$(param.eta)"

make_dir(path)

#////////////////////////////////////////////#
#           INITIALIZE SYSTEM                #
#////////////////////////////////////////////#

flock = Flock(param.N, param.M)

# out_pos = zeros(Float64, 2 * param.N, T)
ranges     = calc_ranges(param.N)
rij_ranges = calc_ranges(size(flock.rij_ids, 1))

nets_file  = open(path * "/nets.csv", "w")
poski_file = open(path * "/poski.csv", "w")

vx = zeros(Float64, length(procs()[2:end]))
vy = zeros(Float64, length(procs()[2:end]))

# vx_nl = zeros(Float64, length(procs()[2:end]))
# vy_nl = zeros(Float64, length(procs()[2:end]))

###========================================####

times    = [(1 + 10^i):(10^(i+1)) for i in 0:2]
times[1] = 1:10

rand(2,4)
length(times)

hcat(zeros(Float64, 3, 1), ones(Float64, 3, 1))


for rep in 1:reps

    println("rep: ", rep)

    # pos_file = open(path * "/pos$(rep).csv", "w")
    # vel_file = open(path * "/vel$(rep).csv", "w")

    out_pos = zeros(Float64, 2*param.N, 1)
    out_vel = zeros(Float64, 2*param.N, 1)

    init_system(flock, param)

    println(nets_file, flock.nij)
    println(poski_file, flock.poski)

    out_pos = flock.pos.s
    out_vel = flock.vel.s

    for k in 1:length(times)

        frec = times[k][1] - 1

        for t in times[k]

            evol_step_range(flock, param, dt, ranges, rij_ranges, vx, vy)

            if frec > 0

                if t % frec == 0
                    println(t)
                    # println(pos_file,t)
                    # println(vel_file,t)
                    # println(pos_file, flock.pos.s)
                    # println(vel_file, flock.vel.s)
                    out_pos = hcat(out_pos, flock.pos.s)
                    out_vel = hcat(out_vel, flock.vel.s)
                end

            else

                if t % 1 == 0
                    println(t)
                    # println(pos_file,t)
                    # println(vel_file,t)
                    # println(pos_file, flock.pos.s)
                    # println(vel_file, flock.vel.s)
                    out_pos = hcat(out_pos, flock.pos.s)
                    out_vel = hcat(out_vel, flock.vel.s)
                end
            end
        end
    end

    # close(pos_file)
    # close(vel_file)
    writecsv(path * "/pos$(rep).csv", out_pos)
    writecsv(path * "/vel$(rep).csv", out_vel)

end

close(nets_file)
close(poski_file)

println("Done")
