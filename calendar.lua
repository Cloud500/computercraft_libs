local Calendar = {}
Calendar.__index = Calendar

function Calendar.calc_value(day_count, divisor, max_value)
    local quotient = math.floor(day_count / divisor)
    local rest = math.fmod(day_count, divisor)

    if rest ~= 0 then
        quotient = quotient + 1
    end

    if max_value then
        local value = math.fmod(quotient, max_value)
        if value == 0 then
            return max_value
        else
            return value
        end
    else
        return quotient
    end
end

function Calendar.day()
    return Calendar.calc_value(os.day(), 1, 30)
end

function Calendar.month()
    return Calendar.calc_value(os.day(), 30, 12)
end

function Calendar.year()
    return Calendar.calc_value(os.day(), 360)
end

function Calendar.timestamp()
    local year = string.format("%04d", Calendar.year())
    local month = string.format("%02d", Calendar.month())
    local day = string.format("%02d", Calendar.day())
    local time = textutils.formatTime(os.time(), true)
    return string.format("%s.%s.%s %s", year, month, day, time)
end

return Calendar