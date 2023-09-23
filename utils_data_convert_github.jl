
function readTimetable(input_file, max_wait_time::Float64)
    T_max = 0.0; n_l = 0 # Line No.
    start_hr = 0.0; start_min = 0.0
    tt_simple = ones(n_dep,n_ts) # create timetable simple version
    timeTable = DataFrame(No = Int[], E = Float64[], L = Float64[])
    for line in readlines(input_file)
        #println("Line:", n_l, " ", line)
        if n_l == 0
            station = split(line, ",")
            n_l += 1
            continue
        end
        line = split(line, ",")
        for i in 1:n_ts
            time = line[i]
            if time != "NaT"
                time = split(time, " ")[2] # !!!DATE IS NOT SAVED HERE!!!
                time = split(time, ":")
                time = [parse(Float64, t) for t in time]
                if (n_l == 1) && (i == 1)
                    start_hr = time[1] # the srating time
                    start_min = time[2]
                end
                #print("Time: ", time, " ")
                time_convert = (time[1] - start_hr)*60 + time[2] - start_min + 20.0 # convert time to minutes (+10 means shift all departure 10 minutes)
                #println("converted time: ", time_convert)
                tt_simple[n_l, i] = time_convert
                push!(timeTable, (i, time_convert-max_wait_time, time_convert))
                #println(typeof(time))
            elseif time == "NaT"
                tt_simple[n_l, n_ts] = tt_simple[n_l, n_ts-1] + 10
                push!(timeTable, (i, tt_simple[n_l, n_ts]-max_wait_time, tt_simple[n_l, n_ts]))
                T_max = tt_simple[n_l, n_ts] + 5.0
                #println(n_l, n_ts)
                continue
            end            
        end
        n_l += 1
    end
    sort!(timeTable, [:L], rev = [false])
    timeTable.no_layer = 1:size(timeTable)[1]
    return timeTable
end

function read_cus_data(input_file, timeTable)
 
    x_c = zeros(Float64, n_c) # customers' x coordinate
    y_c = zeros(Float64, n_c) # customers' y coordinate
    c_l = Vector{Int64}(undef, n_c) # customer's selected layer
    timeTable_ts = Vector{Any}(undef, n_ts)
    for i in 1:n_ts
        timeTable_ts[i] = timeTable[in(i).(timeTable.No), :]
    end
     
    df = CSV.read(input_file, DataFrame, drop=[1])
    
    x_c = df.passenger_X  
    y_c = df.passenger_Y
    no_train = df.passenger_StationID
    no_dep = df.passenger_DepartureTime

    cl = zeros(Int64,n_c)
    for c_id in collect(1:n_c)
        c_l[c_id] = timeTable_ts[no_train[c_id]][no_dep[c_id],:].no_layer
    end
    return x_c, y_c, c_l
end

function read_bs_data(input_file, w_max, coord_cus)
 
    df = CSV.read(input_file, DataFrame, drop=[1])
    
    bs_x = df.busStop_X 
    bs_y = df.busStop_Y
    coord_bs =  [bs_x bs_y]
    n_bs = length(bs_x)
    set_MP = Set{Int64}()
   # get cus within max walking dist, if true, keep this bus stop
   for i in 1:n_bs
      coord_bs_tmp = coord_bs[i,:]
      dist_tmp = [ sqrt(sum((coord_cus[s,:] - coord_bs_tmp).^2)) for s in collect(1:n_c)] 
      idx= findfirst(x->x<w_max, dist_tmp)
      !isnothing(idx) && union!(set_MP,i )
    end
    vec_idx= sort!(collect(set_MP))
   
    append!(x_init, bs_x[vec_idx]) 
    append!(y_init, bs_y[vec_idx]) 
   return n_bs, [bs_x[vec_idx] bs_y[vec_idx]]
end

function read_other_data(input_cgr, input_ts)
     x_ts  = Float64[];  y_ts =Float64[]
     x_cgr = Float64[]; y_cgr = Float64[]
    for line in readlines(input_ts)
        line = split(line, ",")
        push!(x_ts, parse(Float64, line[1])/1000)
        push!(y_ts, parse(Float64, line[2])/1000)
    end
    x_init[1] = mean(x_ts); y_init[1] = mean(y_ts)
    
    for line in readlines(input_cgr)
        line = split(line, ",")
        push!(x_cgr, parse(Float64, line[1])/1000)
        push!(y_cgr, parse(Float64, line[2])/1000)
    end
    return x_ts, y_ts, x_cgr, y_cgr
end

function plot_data()
    plot(title="Data",legendfontsize=7, legend=:topright)
    scatter!(x_bs, y_bs, label="Bus stops", markershape=:square, markercolor=:green, markersize=4,markerstrokewidth=0)
    scatter!((x_init[1],y_init[1]),markershape=:utriangle, label="Depot",markercolor=:black,markersize=8)
    #scatter!(x_init[2:n_bs+1], y_init[2:n_bs+1], label="Bus stops", markershape=:square, markercolor=:green, markersize=4,markerstrokewidth=0)
    scatter!(x_c,y_c, label="Customers", markershape=:circle, markercolor=:blue, markersize=4,markerstrokewidth=0)
    scatter!(x_init[n_bs+2:1+n_ts+n_bs], y_init[n_bs+2:1+n_ts+n_bs], label="Transit stops", markershape=:star5, markercolor=:red, markersize=8,markerstrokewidth=0)
    scatter!(x_init[n_bs+n_ts+2:1+n_ts+n_bs+n_charger], y_init[n_bs+n_ts+2:1+n_ts+n_bs+n_charger], label="Charger", markershape=:utriangle, markercolor=:cyan, markersize=5,markerstrokewidth=0)
end

 