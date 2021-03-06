### ============== ### ============== ### ============== ###
## Numerical simulations of the local and non local
## collective motion model in open space (3D version)
## Martin Zumaya Hernandez
## 21 / 02 / 2017
### ============== ### ============== ### ============== ###

using Quaternions

### ============== ### ============== ### ============== ###
###                 MODEL IMPLEMENTATION
### ============== ### ============== ### ============== ###

function calc_rij(pos, r0)

    rij = zeros(Float64, length(pos), length(pos))

    # compute rij entries
    for i in 1:size(rij,1), j in (i+1):size(rij,1)

        d = norm(pos[i] - pos[j])
        d < r0 && d > zero(Float64) ? rij[j,i] = one(Float64) : rij[j,i] = zero(Float64)

        rij[i,j] = rij[j,i]
    end

    return rij
end

### ============== ### ============== ### ============== ###

function set_Nij(p, Nij)

    N = size(Nij, 1)

    for i in 1:N, j in union(1:i-1, i+1:N)
        rand() < p ? Nij[j, i] = one(Float64) : Nij[j, i] = zero(Float64)
    end
end

### ============== ### ============== ### ============== ###

function calc_interactions(vel, v_n, sp_Nij)

    rows = rowvals(sp_Nij)

    for i in 1:size(sp_Nij, 1)

        range = nzrange(sp_Nij, i)

        length(range) > 0 ? v_n[i] = mean([vel[rows[j]] for j in range ]) : v_n[i] = zeros(3)

    end

end

### ============== ### ============== ### ============== ###
# demasiado ruido
function rot_move_part(pos, vel, v_r, v_n, η, ω)

    q_r = Quaternion(vel)

    #local rotation
    if norm(v_r) != zero(Float64)
        loc_angle = acos(dot(vel, v_r))
        q_r *= qrotation(cross(vel, v_r), ω * loc_angle + η * (2.0 * rand() * pi - pi))
    else
        q_r *= qrotation(cross(vel, [2*rand() - 1, 2*rand() - 1, 2*rand() - 1]), η * (2.0 * rand() * pi - pi))
    end

    #non-local rotation
    if norm(v_n) != zero(Float64)
        non_loc_angle = acos(dot(vel, v_n))
        q_r *= qrotation(cross([q_r.v1, q_r.v2, q_r.v3], v_n), (1.0 - ω) * non_loc_angle + η * (2.0 * rand() * pi - pi))
    else
        q_r *= qrotation(cross([q_r.v1, q_r.v2, q_r.v3], [2*rand() - 1, 2*rand() - 1, 2*rand() - 1]), η * (2.0 * rand() * pi - pi))
    end

    u_vel = normalize([q_r.v1, q_r.v2, q_r.v3])

    vel[1] = u_vel[1]
    vel[2] = u_vel[2]
    vel[3] = u_vel[3]

    pos[1] += u_vel[1]
    pos[2] += u_vel[2]
    pos[3] += u_vel[3]

end

# esta version si funciona pero las particulas siguen en linea recta si no interaccionan
function test_rot_move_part(pos, vel, v_r, v_n, η, ω)

    loc_angle     = ω * cos(dot(vel, v_r))
    non_loc_angle = (1.0 - ω) * acos(dot(vel, v_n))

    # q_r = Quaternion(vel)

    #local rotation
    q_r = qrotation(cross(vel, v_r), loc_angle + η * (2.0 * rand() * pi - pi)) * Quaternion(vel)

    u_vel = [q_r.v1, q_r.v2, q_r.v3]

    #non-local rotation
    q_r = qrotation(cross(u_vel, v_n), non_loc_angle + η * (2.0 * rand() * pi - pi)) * q_r

    u_vel = normalize([q_r.v1, q_r.v2, q_r.v3])

    vel[1] = u_vel[1]
    vel[2] = u_vel[2]
    vel[3] = u_vel[3]

    pos[1] += u_vel[1]
    pos[2] += u_vel[2]
    pos[3] += u_vel[3]

end

function test1_rot_move_part(pos, vel, v_r, v_n, η, ω)

    loc_angle     = ω * acos(dot(vel, v_r))
    non_loc_angle = (1.0 - ω) * acos(dot(vel, v_n))

    noise = randn(3)
    noise_angle = acos(dot(normalize(noise), vel))

    q_r = qrotation(cross(vel, v_r), loc_angle + η * noise_angle) * Quaternion(vel)

    u_vel = [q_r.v1, q_r.v2, q_r.v3]

    q_r = qrotation(cross(u_vel, v_n), non_loc_angle + η * noise_angle) * q_r

    u_vel = [q_r.v1, q_r.v2, q_r.v3]

    q_r = qrotation(cross(u_vel, noise), η * noise_angle) * q_r

    u_vel = normalize([q_r.v1, q_r.v2, q_r.v3])

    vel[1] = u_vel[1]
    vel[2] = u_vel[2]
    vel[3] = u_vel[3]

    pos[1] += u_vel[1]
    pos[2] += u_vel[2]
    pos[3] += u_vel[3]

end

### ============== ### ============== ### ============== ###
###                 SYSTEM EVOLUTION
### ============== ### ============== ### ============== ###

function evolve(pos, vel, v_r, v_n, sp_Nij, r0, η, ω)

    calc_interactions(vel, v_r, sparse(calc_rij(pos, r0)) ) # local
    calc_interactions(vel, v_n, sp_Nij) # non_local

    # map( (p, v, vr, vn) -> rot_move_part(p, v, vr, vn, η, ω), pos, vel, v_r, v_n )
    # map( (p, v, vr, vn) -> test_rot_move_part(p, v, vr, vn, η, ω), pos, vel, v_r, v_n )
    map( (p, v, vr, vn) -> test1_rot_move_part(p, v, vr, vn, η, ω), pos, vel, v_r, v_n )

end

### =============== ### =============== ### =============== ###
### DEFINITION OF INITIAL PARAMETERS
### =============== ### =============== ### =============== ###

N   = parse(Int, ARGS[1]) # number of particles
κ   = parse(Float64, ARGS[2]) # average non-local interactions
ω   = parse(Float64, ARGS[3]) # average non-local interactions
T   = parse(Int, ARGS[4]) # integration time steps
rep = parse(Int, ARGS[5])

# N  = 1024
# N  = 512
# κ = 2
# ω = 0.5

η = 0.15 # noise intensity

# ρ  = 1.0 # density
ρ  = 0.3 # density
L  = cbrt(N / ρ) # size of box

l = 0.1 # Regimen de velocidad

dt = 1.0 # Time integration step
v0 = 1.0 # particle's speed

r0 = (v0 * dt) / l

p = κ / (N-1) # link probability

times = [convert(Int, exp10(i)) for i in 0:T]

### ============== ### ============== ### ============== ###
### OUTPUT
### ============== ### ============== ### ============== ###

parent_folder_path = "$(homedir())/art_DATA/NLOC_DATA_3D"
folder_path        = parent_folder_path * "/DATA/data_N_$(N)"
reps_path          = folder_path * "/data_N_$(N)_k_$(κ)_w_$(ω)"

try
    mkdir(parent_folder_path)
catch error
    println("Parent folder already exists")
end

try
    mkdir(parent_folder_path * "/DATA")
catch error
    println("Parent folder already exists")
end

try
    mkdir(folder_path)
catch error
    println("Folder already exists")
end

try
    mkdir(reps_path)
catch error
    println("Parameter folder already exists")
end

println("rep: $(rep)")

### =============== ### =============== ### =============== ###
### INITIALIZATION OF PARTICLES INITIAL POSITIONS AND VELOCIDITES
### =============== ### =============== ### =============== ###

# array of random initial particles' postitions
pos = [ [2*rand()*L - L, 2*rand()*L - L, 2*rand()*L - L] for i in 1:N ]

# array of particles' velocities
vel = v0 * [ normalize([2*rand() - 1, 2*rand() - 1, 2*rand() - 1]) for i in 1:N ]

# local metric interactions
v_r = [zeros(3) for i in 1:N]

# non local topological interactions
v_n = [zeros(3) for i in 1:N]

# non-local interaction network definition
Nij = zeros(Float64, N, N)

set_Nij(p, Nij)
sp_Nij = sparse(Nij)

# println("Ended Init")

pos_file = open(reps_path * "/pos_$(rep).dat", "w+")
vel_file = open(reps_path * "/vel_$(rep).dat", "w+")
net_file = open(reps_path * "/net_$(rep).dat", "w+")

write(net_file, Nij)
close(net_file)

### ============== ### ============== ### ============== ###
### SYSTEM EVOLUTION
### ============== ### ============== ### ============== ###

for i in 1:(length(times) - 1)

    if i > 1

        for t in (times[i]+1):times[i+1]

            evolve(pos, vel, v_r, v_n, sp_Nij, r0, η, ω)

            if t % times[i] == 0 || t % times[i-1] == 0
                println("//////// ", t)
                write(pos_file, vcat(pos...))
                write(vel_file, vcat(vel...))
            end
        end

    else

        for t in (times[i]+1):times[i+1]

            evolve(pos, vel, v_r, v_n, sp_Nij, r0, η, ω)

            if t % times[i] == 0
                println("//////// ", t)
                write(pos_file, vcat(pos...))
                write(vel_file, vcat(vel...))
            end
        end

    end

end

close(pos_file)
close(vel_file)

println("Done all")
