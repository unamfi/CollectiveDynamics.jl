### ============== ### ============== ### ============== ###
## Compute particles MSD
## with respect to center of mass
## Martin Zumaya Hernandez
## 11 / 07 / 2017
### ============== ### ============== ### ============== ###

using PyPlot, CollectiveDynamics.DataAnalysis, Polynomials, LaTeXStrings

### ================================== ###

N = 4096
N = 1024
N = 512
N = 256
N = 128
N = 100
N = 64

τ = 6
τ = 5
τ = 4
τ = 3

times = get_times(τ)
x_vals = broadcast(x -> log10(x), times)

### ================================== ###

folder = "NLOC_DATA"
folder = "NLOC_DATA_3D"
folder = "NLOC_MET_3D"
folder = "NLOC_TOP_3D"
folder = "NLOC_TOP_3D_MEAN"
folder = "TFLOCK_NLOC_DATA"
folder = "TFLOCK_DATA"
folder = "SVM_GRID_FN_3D"

folder_path = "$(homedir())/art_DATA/$(folder)/EXP/exp_data_N_$(N)"
folder_path = "$(homedir())/art_DATA/$(folder)/DATA/data_N_$(N)"

# eta_folders = readdir(folder_path)

### ================================== ###

order_files = filter( x -> ismatch(r"^order.", x), readdir(folder_path))
exp_files = filter( x -> ismatch(r"^exp.", x), readdir(folder_path))
nn_files = filter( x -> ismatch(r"^nn_mean.", x), readdir(folder_path))

means = zeros(length(times), length(order_files))
orders = zeros(length(times), length(order_files))
nn_means = zeros(length(times), length(order_files))

std_means = zeros(length(times), length(order_files))

### ================================== ###
# para VSK
capt = [match(r"_(\d+\.\d+)\.\w+$|_(\d+\.\d+e-5)\.\w+$", f).captures for f in order_files]
vals = [parse(Float64, vcat(capt...)[i]) for i in find(x -> x != nothing, vcat(capt...))]


# para NLOC
vals = [ parse(Float64, match(r"^\w+_(\d+\.\d+)", x).captures[1]) for x in order_files ]

### ================================== ###
# i = 3
for i in sortperm(vals)

    println(i)

    raw_data = reinterpret(Float64, read(folder_path * "/" * exp_files[i]))
    exp_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    raw_data = reinterpret(Float64, read(folder_path * "/" * order_files[i]))
    order_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    raw_data = reinterpret(Float64, read(folder_path * "/" * nn_files[i]))
    nn_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    means[:, i] = mean(exp_data, 2)
    std_means[:, i] = std(exp_data, 2)
    orders[:, i] = mean(order_data, 2)
    nn_means[:, i] = mean(nn_data, 2)

end

### ================================== ###

d_means = zeros(length(times), length(order_files))
d_nn_means = zeros(length(times), length(order_files))

for i in sortperm(vals)
    x0 = means[1, i]
    d_means[:,i] = broadcast(x -> (x - x0)^2, means[:, i])
end

for i in sortperm(vals)
    x0 = nn_means[1, i]
    d_nn_means[:,i] = broadcast(x -> (x - x0)^2, nn_means[:, i])
end

r_vals = broadcast(x -> log10(x), d_means)
r_nn_vals = broadcast(x -> log10(x), d_nn_means)

x_l = 320

r_fit_vals = [polyfit(x_vals[x_l:end], r_vals[x_l:end, i], 1) for i in sortperm(vals)]
r_nn_fit_vals = [polyfit(x_vals[x_l:end], r_nn_vals[x_l:end, i], 1) for i in sortperm(vals)]

### ================================== ###
# draft pplots

m_plot = plot(times, means[:, sortperm(vals)], leg = false, xscale = :log10, yscale = :log10, lw = 1.4, xlabel = "t", ylabel = "r_ij(t)")

nn_plot = plot(times, nn_means[:, sortperm(vals)], leg = false, xscale = :log10, yscale = :log10, lw = 1.4, xlabel = "t", ylabel = "r_ij(t)")


dm_plot = scatter(times[x_l:end], d_means[x_l:end, :], xscale = :log10, yscale = :log10, lw = 1.5, leg = false, marker = :o, alpha = 0.5)

dnn_plot = scatter(times[x_l:end], d_nn_means[x_l:end, :], xscale = :log10, yscale = :log10, lw = 1.5, leg = false, marker = :o, alpha = 0.5)

plot(dm_plot, dnn_plot, layout = 2)

plot(m_plot, dm_plot, layout = 2)
plot(nn_plot, dnn_plot, layout = 2)


dif_c = plot(vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], marker = :o, xscale = :log10, xlabel = "k", ylabel = "D", title = "Diffusion Coeffcient", titlefont = font(10), yscale = :log10)

plot!(dif_c, vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], marker = :rect)

dif_e = plot(vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], marker = :o, xscale = :log10, xlabel = "k", ylabel = "alpha", title = "Diffusion Exponent", titlefont = font(10))

plot!(dif_e, vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], marker = :rect)

### ================================== ###
# print plots

plt[:rc]("text", usetex=true)
plt[:rc]("font", family="serif")
plt[:rc]("font", serif="New Century Schoolbook")

fs = 12
ls = 10

plt[:clf]()

### ================================== ###

fig = plt[:figure](num = 1, dpi = 300, facecolor="w", edgecolor="k")
fig[:set_size_inches](2.4, 1.92, forward = true)

### ================================== ###
## d_rij met

ax = fig[:add_subplot](111)
ax[:plot](times, d_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 200

ax[:plot](times[x_f:end], broadcast(x-> 0.5exp10(-2)x , times[x_f:end]), "r--", lw = 0.8)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](3, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(0), exp10(3), exp10(6), exp10(8)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

ax[:text](exp10(6), 0.5exp10(-2), L"t", ha="center", va="center", size=fs)
ax[:text](3exp10(1), exp10(8), L"\langle \Delta r_{ij} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](1.5exp10(3), 1.8exp10(7), L"\kappa", ha="center", va="center", size=0.8fs)

ax[:annotate]("", xy = (exp10(4), 1.5exp10(2)), xycoords = "data", xytext = (1.5exp10(3), 5exp10(6)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

fig[:savefig]("delta_rij_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## d_rnn met

ax = fig[:add_subplot](111)
ax[:plot](times, d_nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 200

ax[:plot](times[x_f:end], broadcast(x-> exp10(-4)x , times[x_f:end]), "r--", lw = 0.8)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](3, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(0), exp10(3), exp10(6)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

ax[:text](exp10(6), 1.8exp10(-4), L"t", ha="center", va="center", size=fs)
ax[:text](3.5exp10(1), exp10(6), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](1.5exp10(3), 1.8exp10(5), L"\kappa", ha="center", va="center", size=0.8fs)

ax[:annotate]("", xy = (8exp10(3), 0.3exp10(1)), xycoords = "data", xytext = (1.5exp10(3), 0.6exp10(5)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

fig[:savefig]("delta_rnn_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion coefficients met

ax = fig[:add_subplot](111)

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xlim](0.5exp10(-2), 2exp10(1))

plt[:yticks]([exp10(-2), exp10(-1), exp10(0), exp10(1), exp10(2)])
plt[:xticks]([exp10(-2), exp10(-1), exp10(0), exp10(1)])

ax[:text](2exp10(-3), 4.5exp10(2), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](25, 0.8exp10(-3), L"\kappa", ha="center", va="center", size=fs)

fig[:savefig]("coef_diff_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion exponents met

ax = fig[:add_subplot](111)

ax[:plot](vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

plt[:xscale]("log")
# plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xlim](0.5exp10(-2), 2exp10(1))

plt[:xticks]([exp10(-2), exp10(-1), exp10(0), exp10(1)])
# plt[:yticks](collect(0.85:0.25:1))

ax[:text](2.3exp10(-3), 1.02, L"\alpha(\kappa)", ha="center", va="center", size=fs)
ax[:text](25, 0.88, L"\kappa", ha="center", va="center", size=fs)

fig[:savefig]("exp_diff_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)


### ================================== ###
## d_rij top

ax = fig[:add_subplot](111)
ax[:plot](times, d_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 200

ax[:plot](times[x_f:end], broadcast(x-> exp10(-2)x , times[x_f:end]), "r--", lw = 0.8)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](3, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(0), exp10(3), exp10(6), exp10(9)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

ax[:text](exp10(6), 0.5exp10(-1), L"t", ha="center", va="center", size=fs)
ax[:text](3exp10(1), 0.8exp10(9), L"\langle \Delta r_{ij} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](1.5exp10(3), exp10(8), L"\kappa", ha="center", va="center", size=0.8fs)

ax[:annotate]("", xy = (exp10(4), 0.7exp10(3)), xycoords = "data", xytext = (1.5exp10(3), 0.2exp10(8)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

fig[:savefig]("delta_rij_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## d_rnn met

ax = fig[:add_subplot](111)
ax[:plot](times, d_nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 200

ax[:plot](times[x_f:end], broadcast(x-> exp10(-4)x , times[x_f:end]), "r--", lw = 0.8)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](3, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(0), exp10(3), exp10(6)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

ax[:text](exp10(6), 1.8exp10(-4), L"t", ha="center", va="center", size=fs)
ax[:text](3.5exp10(1), exp10(6), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](1.5exp10(3), exp10(8), L"\kappa", ha="center", va="center", size=0.8fs)

ax[:annotate]("", xy = (exp10(4), 0.7exp10(3)), xycoords = "data", xytext = (1.5exp10(3), 0.2exp10(8)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

fig[:savefig]("delta_rnn_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

### ================================== ###

plt[:clf]()
