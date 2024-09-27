using PyCall
using Reactive
using Chain
using Dates
using CSV
using DataFrames
using PrintedOpticalParticleSpectrometer

const u3 = pyimport("u3")
const U3HANDLE = u3.U3()
const portPOPS = PrintedOpticalParticleSpectrometer.config("/dev/ttyS0")
const oneHz = every(1.0)

U3HANDLE.configIO(
    EnableCounter0 = false,
    EnableCounter1 = false,
    NumberOfTimersEnabled = 0,
    FIOAnalog = 0,
)

const hrstr = map(_ -> Dates.format(now(), "yyyymmdd.HH"), oneHz)
const outfile = map(str -> "/home/puser/data/pops/" * str * "0000.csv", droprepeats(hrstr))

extract(x, i) = @chain split(x, ",") getindex(_, i) parse.(Float64, _)

function packet()
    tc = Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    T = try
        U3HANDLE.getAIN(1, longSettle = true, quickSample = false) * 100.0 - 40.0
    catch
        NaN
    end

    RH = try
        U3HANDLE.getAIN(0, longSettle = true, quickSample = false) * 100.0
    catch
        NaN
    end

    pops = PrintedOpticalParticleSpectrometer.get_current_record()

    Q = try
        extract(pops, 2)
    catch
        NaN
    end

    N = try
        b = split(pops, "\r")
        c = split(b[1], ",")
        psd = extract(b[1], 7:length(c))
        N = sum(psd)
    catch
        NaN
    end

    psd = try
        b = split(pops, "\r")
        c = split(b[1], ",")
        psd = extract(b[1], 7:length(c))
    catch
        zeros(16) .* NaN
    end

    df1 = DataFrame(
        t = tc,
        T = round(T; digits = 2),
        RH = round(RH; digits = 2),
        Q = Q,
        N = N,
    )
    df2 = DataFrame(psd', :auto)
    df = hcat(df1, df2)
    df |> CSV.write(outfile.value; append = true)
end

sleep(120)
@async PrintedOpticalParticleSpectrometer.stream(
    portPOPS,
    "/home/puser/data/popsraw/popsraw",
)

sleep(10)
const daqLoop = map(_ -> packet(), oneHz)
