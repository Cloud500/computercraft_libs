local calendar = require "/libs/calendar"

local Logger = {}
--Logger.__index = Logger

function Logger.__init__(baseClass, level, name, write_term_log, write_log_file)
    print(level, name, write_term_log, write_log_file)
    self = {}
    --setmetatable(self, Logger)
    self.log_level = level or 1
    self.name = name or "logger"
    self.logfile = "/logs/" .. name or "logger" .. ".log"
    self.write_term_log = write_term_log or true
    self.write_log_file = write_log_file or false
    self.log_level_data = {
        [1] = { ["name"] = "error", ["color"] = colors.red },
        [2] = { ["name"] = "warning", ["color"] = colors.orange },
        [3] = { ["name"] = "info", ["color"] = colors.white },
        [4] = { ["name"] = "debug", ["color"] = colors.gray }
    }
    setmetatable(self, { __index = Logger })
    return self
end

setmetatable(Logger, { __call = Logger.__init__ })

function Logger.new(logger_obj, name)
    if logger_obj then
        return Logger(logger_obj.log_level, string.format("%s_%s", logger_obj.name, name),
                logger_obj.write_term_log, logger_obj.write_log_file)
    else
        return Logger(nil, logger_obj.name, nil, nil)
    end
end

function Logger:format_message(msg, level)
    local date_time = string.format("%02d.%02d.%04d %s", calendar.day(), calendar.month(), calendar.year(),
            textutils.formatTime(os.time(), true))
    local prefix = string.format("%s %s", date_time, self.log_level_data[level]["name"])

    return string.format("%-24s [%s] %s", prefix, self.name, msg)
end

function Logger:term_output(msg, level)
    local curr_color = term.getTextColor()
    term.setTextColor(self.log_level_data[level]["color"])
    print(self:format_message(msg, level))
    term.setTextColor(curr_color)
end

function Logger:file_output(msg, level)
    local file
    if not fs.exists(logfile) then
        file = fs.open(logfile, "w")
    else
        file = fs.open(logfile, "a")
    end
    file.writeLine(self:format_message(msg, level))
    file.close()
end

function Logger:logger(msg, level)
    self:term_output(msg, level)
    if self.write_log_file then
        self:file_output(msg, level)
    end
end

function Logger:set_log_name(name)
    self.logfile = "/logs/" .. name .. ".log"
end

function Logger:log_error(msg)
    if self.log_level >= 1 then
        self:logger(msg, 1)
    end
end

function Logger:log_warning(msg)
    if self.log_level >= 2 then
        self:logger(msg, 2)
    end
end

function Logger:log_info(msg)
    if self.log_level >= 3 then
        self:logger(msg, 3)
    end
end

function Logger:log_debug(msg)
    if self.log_level >= 4 then
        self:logger(msg, 4)
    end
end

function Logger:error_exit(msg)
    self:logger(msg, 1)
    error()
end

return Logger