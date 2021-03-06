using Plots, CollectiveDynamics.DataAnalysis

# gr()
pyplot()

### ================================== ###

N = parse(Int, ARGS[1])
τ = parse(Int, ARGS[2])
mod_flag = parse(Int, ARGS[3])

# N = 1024
# N = 512
# N = 256
# N = 128
# N = 64

# τ = 5
# τ = 6

# mod_flag = 1
tau = get_times(τ)

### ================================== ###

if mod_flag == 1
    folder_path = "$(homedir())/art_DATA/TFLOCK_NLOC_DATA/DATA/data_N_$(N)"
    v0 = 0.1
elseif mod_flag == 0
    # folder_path = "$(homedir())/art_DATA/NLOC_DATA_3D/DATA/data_N_$(N)"
    # folder_path = "$(homedir())/art_DATA/NLOC_DATA_MOD/DATA/data_N_$(N)"
    folder_path = "$(homedir())/art_DATA/NLOC_DATA_MOD_3D/DATA/data_N_$(N)"
    v0 = 1.0
end

# files = filter(x -> match(r"._(\d+.\d+).dat", x).captures[1] == η , readdir(folder_path))
folders = readdir(folder_path)

### ================================== ###

if mod_flag == 1

    η_vals = unique([match(r"^\w+(\d+\.\d+)", f).captures[1] for f in folders])
    T_vals = unique([match(r"._T_(\d+\.\d+).", f).captures[1] for f in readdir(folder_path * "/" * folders[1]) ] )
    n_nl_vals = unique([match(r"(\d+\.\d+)$", f).captures[1] for f in readdir(folder_path * "/" * folders[1]) ] )

    # i = 1
    for i in 1:length(folders)

        println(folders[i])

        # j = 1
        for j in 1:length(n_nl_vals)

            trays_plots = Any[]
            exp_plots   = Any[]
            order_plots = Any[]

            println(n_nl_vals[j])

            data_path = folder_path * "/" * folders[i] * "/" * folders[i] * "_T_$(T_vals[1])_nl_$(n_nl_vals[j])"
            # data_path = folder_path * "/" * folders[i] * "/" * folders[i] * "_k_$(k)_w_0.5"
            # data_path = folder_path * "/" * folders[i]

            means = Array{Float64}[]
            psi   = Array{Float64}[]

            reps = unique([match(r"\w+_(\d+)\.\w+$", f).captures[1] for f in readdir(data_path)])

            for r in reps

                println(r)

                raw_data = reinterpret(Float64, read(data_path * "/pos_$(r).dat"))
                pos_data = transpose(reshape(raw_data, 3N, div(length(raw_data), 3N)))
                # pos_data = reshape(raw_data, 3N, div(length(raw_data), 3N))

                raw_data = reinterpret(Float64, read(data_path * "/vel_$(r).dat"))
                vel_data = reshape(raw_data, 3N, div(length(raw_data), 3N))
                # vel_data = reshape(raw_data, 3N, div(length(raw_data), 3N))

                x = view(pos_data, :, 1:3:3N)
                y = view(pos_data, :, 2:3:3N)
                z = view(pos_data, :, 3:3:3N)

                push!(trays_plots, plot(x, y, z, leg = false, tickfont = font(3)))

                pos_data[:, 1:3:3N] .-= mean(pos_data[:, 1:3:3N], 2)
                pos_data[:, 2:3:3N] .-= mean(pos_data[:, 2:3:3N], 2)
                pos_data[:, 3:3:3N] .-= mean(pos_data[:, 3:3:3N], 2)

                tr_pos_data = transpose(pos_data)

                means = [mean(calc_rij_3D_vect(tr_pos_data[:, i])) for i in 1:size(tr_pos_data,2)]

                psi = (1. / v0) * [norm(mean([ [vel_data[i, j], vel_data[i+1, j], vel_data[i+2, j] ] for i in 1:3:3N])) for j in 1:size(vel_data, 2)]

                # push!(exp_plots, plot(tau, means, xscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))
                push!(exp_plots, plot(tau, means, xscale = :log10, yscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))

                push!(order_plots, plot(tau, psi, xscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))
            end

            plot(trays_plots...,  size = (1270,820))
            savefig("$(homedir())/figures/modelo_cvgn/reps_trays_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_trays_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_trays_N_$(N)_$(folders[i]).png")

            plot(exp_plots..., size = (1270,820))
            savefig("$(homedir())/figures/modelo_cvgn/reps_exp_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_exp_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_exp_N_$(N)_$(folders[i]).png")

            plot(order_plots..., size = (1270,820))
            savefig("$(homedir())/figures/modelo_cvgn/reps_order_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_order_N_$(N)_$(folders[i])_T_$(T_vals[1])_nl_$(n_nl_vals[j]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/modelo_cvgn/reps_order_N_$(N)_$(folders[i]).png")
        end
    end

### ================================== ###

elseif mod_flag == 0

    κ_vals = unique([match(r"^\w+_k_(\d+\.\d+)", f).captures[1] for f in folders])
    w_vals = unique([match(r"w_(\d+\.\d+)$", f).captures[1] for f in folders])

    p_vals = unique([match(r"(\w_\d+\.\d+_\w_\d+\.\d+)$", f).captures[1] for f in folders])

    # i = 1
    for i in 1:length(folders)

        println(folders[i])

        # j = 1
        for j in 1:length(p_vals)

            trays_plots = Any[]
            exp_plots   = Any[]
            order_plots = Any[]

            println(p_vals[j])

            data_path = folder_path * "/" * folders[i]

            means = Array{Float64}[]
            psi   = Array{Float64}[]

            reps = unique([match(r"\w+_(\d+)\.\w+$", f).captures[1] for f in readdir(data_path)])

            for r in reps

                println(r)

                raw_data = reinterpret(Float64, read(data_path * "/pos_$(r).dat"))
                pos_data = transpose(reshape(raw_data, 3N, div(length(raw_data), 3N)))
                # pos_data = transpose(reshape(raw_data, 2N, div(length(raw_data), 2N)))

                raw_data = reinterpret(Float64, read(data_path * "/vel_$(r).dat"))
                vel_data = reshape(raw_data, 3N, div(length(raw_data), 3N))
                # vel_data = reshape(raw_data, 2N, div(length(raw_data), 2N))

                x = view(pos_data, :, 1:3:3N)
                y = view(pos_data, :, 2:3:3N)
                z = view(pos_data, :, 3:3:3N)

                # x = view(pos_data, :, 1:2:2N)
                # y = view(pos_data, :, 2:2:2N)

                push!(trays_plots, plot(x, y, z, leg = false, tickfont = font(3)))
                # push!(trays_plots, plot(x, y, leg = false, tickfont = font(3)))

                pos_data[:, 1:3:3N] .-= mean(pos_data[:, 1:3:3N], 2)
                pos_data[:, 2:3:3N] .-= mean(pos_data[:, 2:3:3N], 2)
                pos_data[:, 3:3:3N] .-= mean(pos_data[:, 3:3:3N], 2)

                # pos_data[:, 1:2:2N] .-= mean(pos_data[:, 1:2:2N], 2)
                # pos_data[:, 2:2:2N] .-= mean(pos_data[:, 2:2:2N], 2)

                tr_pos_data = transpose(pos_data)

                means = [mean(calc_rij_3D_vect(tr_pos_data[:, i])) for i in 1:size(tr_pos_data,2)]

                # means = [mean(calc_rij_2D_vect(tr_pos_data[:, i])) for i in 1:size(tr_pos_data,2)]

                psi = (1. / v0) * [norm(mean([ [vel _data[i, j], vel_data[i+1, j], vel_data[i+2, j] ] for i in 1:3:3N])) for j in 1:size(vel_data, 2)]
                # psi = (1. / v0) * [norm(mean([ [vel_data[i, j], vel_data[i+1, j]] for i in 1:2:2N])) for j in 1:size(vel_data, 2)]

                # push!(exp_plots, plot(tau, means, xscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))
                push!(exp_plots, plot(tau, means, xscale = :log10, yscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))

                push!(order_plots, plot(tau, psi, xscale = :log10, marker = :o, markersize = 1.2, leg = false, xlabel = "$(r)", tickfont = font(8)))
            end

            # plot(trays_plots...,  size = (1270,820))
            # # savefig("$(homedir())/figures/mod_nloc/reps_trays_N_$(N)_$(p_vals[i]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc/reps_trays_N_$(N)_$(p_vals[i]).png")
            #
            # plot(exp_plots..., size = (1270,820))
            # # savefig("$(homedir())/figures/mod_nloc/reps_exp_N_$(N)_$(p_vals[i]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc/reps_exp_N_$(N)_$(p_vals[i]).png")
            #
            # plot(order_plots..., size = (1270,820))
            # # savefig("$(homedir())/figures/mod_nloc/reps_order_N_$(N)_$(p_vals[i]).png")
            # savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc/reps_order_N_$(N)_$(p_vals[i]).png")

            plot(trays_plots...,  size = (1270,820))
            # savefig("$(homedir())/figures/mod_nloc_3d/reps_3D_trays_N_$(N)_$(p_vals[i]).png")
            savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc_3d/reps_3D_trays_N_$(N)_$(p_vals[i]).png")

            plot(exp_plots..., size = (1270,820))
            # savefig("$(homedir())/figures/mod_nloc_3d/reps_3D_exp_N_$(N)_$(p_vals[i]).png")
            savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc_3d/reps_3D_exp_N_$(N)_$(p_vals[i]).png")

            plot(order_plots..., size = (1270,820))
            # savefig("$(homedir())/figures/mod_nloc_3d/reps_3D_order_N_$(N)_$(p_vals[i]).png")
            savefig("$(homedir())/Google\ Drive/proyecto_martin/imagenes/mod_nloc_3d/reps_3D_order_N_$(N)_$(p_vals[i]).png")
        end
    end
end

# gui()
# plot(trays_plots[9])
