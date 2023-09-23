
using DataFrames, CSV, Distributions, Distances
using Plots
include("utils_data_convert.jl") 
#E_init = E_max
str_dataset = "dataset5\\"
MP_dist="-d1400"
path_data_matlab = "C:\\Users\\your path\\" * str_dataset
input_bs  = path_data_matlab * "busStopXY" * MP_dist * ".csv"
input_cgr = path_data_matlab * "chargerXY.txt"
input_pax = path_data_matlab * "paxData.csv"
input_ts  = path_data_matlab * "stationXY.txt"
input_tt  = path_data_matlab * "transitTimetable.txt"

# df = CSV.read(input_pax, DataFrame, drop=[1])
n_c = countlines(input_pax)-1# number of customers
n_ts = countlines(input_ts) # number of transit stations
n_dep = countlines(input_tt) -1 # number of departures
n_charger = countlines(input_cgr) # number of chargers
cgr_speed = 50/60 # 50kw/h
w_max = 1 # kilometers
μ = 0.5 # service time per person
x_init = [0.0]; y_init = [0.0]
# two types of buses
n_bus_type = 2
n_k_type=zeros(Int, n_bus_type)
n_k_type=[30, 0]
n_k = sum(n_k_type)

E_init = zeros(n_k); E_max = zeros(n_k)
E_min = zeros(n_k); Q_max = zeros(n_k); beta = zeros(n_k)
Q_max_type  = [24, 80]
beta_type   = [1.23, 1.9]
E_max_type  = [118, 370]
E_min_type  = [11.8, 37]
v_k    = 30/60  #speed of veh 
max_wait_time = 15.0 # time windows at transit station
demandPeakness = 1 # 0 or 1, 1 means peak demand based on the coef of demandPeakness in the matlab file
v_walk = 0.085  # 5.1 km/hr
veh_id =0
for s= 1:n_bus_type
    for j= 1:n_k_type[s]
        veh_id += 1
        Q_max[veh_id] = Q_max_type[s]
        E_max[veh_id] = E_max_type[s]
        E_min[veh_id] = E_min_type[s]
        beta[veh_id]  = beta_type[s]
    end
end
@show(n_k_type, Q_max, E_max, E_min, beta, max_wait_time, demandPeakness)

timeTable  = readTimetable(input_tt, max_wait_time)
x_c, y_c, c_l  = read_cus_data(input_pax, timeTable)
x_ts, y_ts, x_cgr, y_cgr = read_other_data(input_cgr, input_ts)
coord_cus = [x_c y_c]
n_bs , coord_bs = read_bs_data(input_bs, w_max, coord_cus) 
x_init = vcat(x_init, x_ts)
x_init = vcat(x_init, x_cgr)
y_init = vcat(y_init, y_ts)
y_init = vcat(y_init, y_cgr)
# @show(n_bs , coord_bs)
# @show(x_init)
# plot_data()

# Output file
n_chg_dummy = 3;n_bus_type=1;
# CSV.write("Timetable_c$(n_c).csv",timeTable)
open(path_data_matlab * "c-$(n_c)"*MP_dist*".txt", "w") do f
    write(f, "$(n_c) $(n_bs) $(n_ts) $(n_bus_type) $(w_max) $(μ) $(v_k) $(v_walk) \n") 
    for s=1:n_bus_type
        write(f, "$(n_k_type[s]) $(Q_max_type[s]) $(beta_type[s]) $(E_max_type[s]) $(E_min_type[s])\n")
    end
    write(f, "$(n_charger) $(cgr_speed) $(cgr_speed)\n")
    write(f, "0 $(x_init[1]) $(y_init[1])\n")
    for i in 1:n_c
        write(f, "$i $(x_c[i]) $(y_c[i]) $(c_l[i])\n")
    end    
    for i in 2:length(x_init)
        write(f, "$(n_c+i-1) $(x_init[i]) $(y_init[i])\n")
    end
end

