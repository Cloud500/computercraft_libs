local calendar = require "/libs/calendar"
local log = Logger.new(__logger, "conn")

local NoTCP = {}

function NoTCP.__init__(baseClass, modem, send_channel, receive_channel)
    local self = {}

    self.modem = modem
    self.send_channel = send_channel
    self.receive_channel = receive_channel
    log:log_debug(string.format("New ConnManager - modem: %s; send_channel: %d; receive_channel: %d",
            self.modem, self.send_channel, self.receive_channel))

    setmetatable(self, { __index = NoTCP })
    return self
end

setmetatable(NoTCP, { __call = NoTCP.__init__ })

function NoTCP:send_message(message_obj)
    log:log_debug(self.modem)
    self.modem.open(self.send_channel)
    self.modem.transmit(self.send_channel, self.receive_channel, message_obj)
    self.modem.close(self.send_channel)
    log:log_info("Send Message")
    log:log_debug(string.format("Message: %s", textutils.serialize(message_obj)))
end

function NoTCP:build_message(target, type, action, data)
    local label = os.getComputerLabel()
    local timestamp = calendar.timestamp()
    local message_obj = {}
    local message_head = {
        ["sender"] = label,
        ["target"] = target,
        ["timestamp"] = timestamp
    }
    local message_body = {
        ["type"] = type,
        ["action"] = action,
        ["data"] = data
    }
    message_obj["head"] = message_head
    message_obj["body"] = message_body
    return message_obj
end

function NoTCP:build_and_send_message(target, type, action, data)
    self:send_message(self:build_message(target, type, action, data))
end

function NoTCP:validate_message(message_obj, sender)
    log:log_debug(string.format("Validate %s with me (%s) and sender (%s)", message_obj,
            os.getComputerLabel(), sender))
    if message_obj["head"]["sender"] and message_obj["head"]["target"] then
        if message_obj["head"]["target"] == os.getComputerLabel() and message_obj["head"]["sender"] == sender then
            log:log_debug("Validate successful")
            return true
        end
    end
    log:log_debug("Validate unsuccessful")
    return false
end

function NoTCP:process_message(message_obj, sender)
    if sender then
        if not self:validate_message(message_obj, sender) then
            log:log_warning(string.format("Message is not for me", textutils.serialize(message_obj)))
            return nil
        end
    end

    if message_obj["body"]["type"] and message_obj["body"]["action"] and message_obj["body"]["data"] then
        local message_body = {
            ["type"] = message_obj["body"]["type"],
            ["action"] = message_obj["body"]["action"],
            ["data"] = message_obj["body"]["data"]
        }
        return message_body
    else
        return nil
    end
end

function NoTCP:wait_for_message(sender, type, action, timeout)
    log:log_info("Waiting for message")
    timeout = timeout or 5
    local timeout_timer = os.startTimer(timeout)
    self.modem.open(self.receive_channel)
    while true do
        local event = { os.pullEvent() }
        if event[1] == "modem_message" then
            log:log_info("Message received")
            log:log_debug(string.format("Message raw: %s", textutils.serialize(event[5])))
            message_obj = self:process_message(event[5], sender)
            if message_obj then
                log:log_debug(string.format("Message object: %s", textutils.serialize(message_obj)))
                local message_ok = true
                if type then
                    log:log_debug(string.format("Message type: %s, expected: %s", message_obj["type"],
                            type))
                    if message_obj["type"] ~= type then
                        message_ok = false
                    end
                end
                if action then
                    log:log_debug(string.format("Message action: %s, expected: %s", message_obj["action"],
                            action))
                    if message_obj["action"] ~= action then
                        message_ok = false
                    end
                end

                if message_ok then
                    self.modem.close(self.receive_channel)
                    return message_obj
                end
            end
        elseif event[1] == "timer" and event[2] == timeout_timer then
            log:log_warning(string.format("Expected message from %s not received", sender))
            log:log_debug(string.format("sender: %s; type: %s; action: %s; timeout: %s", sender, type,
                    action, timeout))
            self.modem.close(self.receive_channel)
            return nil
        end
    end
end

function NoTCP:send_and_receive_message(message_obj, target, type, action, timeout)
    self:send_message(message_obj)
    return self:wait_for_message(target, type, action, timeout)
end

function NoTCP:receive_and_send_message(message_obj, sender, type, action, timeout)
    local result = self:wait_for_message(sender, type, action, timeout)
    self:send_message(message_obj)
    return result
end

return NoTCP
