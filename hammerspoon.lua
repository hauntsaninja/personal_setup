math.randomseed(os.time())

local mash = {"cmd", "alt", "ctrl"}
hs.fnutils.each({
    { key = "a", app = "Atom" },
    { key = "b", app = "Bear" },
    { key = "c", app = "Calendar" },
    { key = "f", app = "Firefox" },
    { key = "g", app = "Google Chrome" },
    { key = "i", app = "iTunes" },
    { key = "l", app = "Slack" },
    { key = "m", app = "Messages" },
    { key = "p", app = "Spotify" },
    { key = "n", app = "Notes" },
    { key = "s", app = "Safari" },
    { key = "t", app = "Terminal" },
    { key = "v", app = "Visual Studio Code" },
}, function(item)
    local appact = function()
        hs.application.launchOrFocus(item.app)
        local app = hs.appfinder.appFromName(item.app)
        if app then
            app:activate()
        end
    end
    hs.hotkey.bind(mash, item.key, appact)
end)

local function adjustwin(x, y, w, h)
    return function()
        local win = hs.window.focusedWindow()
        if not win then return end

        local f = win:frame()
        local max = win:screen():frame()

        f.x = (max.w * x) + max.x
        f.y = (max.h * y) + max.y
        f.w = max.w * w
        f.h = max.h * h

        win:setFrame(f)
    end
end

hs.hotkey.bind(mash, "left", adjustwin(0, 0, 0.5, 1))
hs.hotkey.bind(mash, "right", adjustwin(0.5, 0, 0.5, 1))
hs.hotkey.bind(mash, "up", adjustwin(0, 0, 1, 0.5))
hs.hotkey.bind(mash, "down", adjustwin(0, 0.5, 1, 0.5))

-- Randomly placed largeish window
hs.hotkey.bind(mash, ".", function()
    local w = 0.5 + math.random() * 0.5
    local h = 0.5 + math.random() * 0.5
    local x = math.random() * (1-w)
    local y = math.random() * (1-h)
    adjustwin(x, y, w, h)()
end)

-- Randomly placed smallish window
hs.hotkey.bind(mash, ",", function()
    local x = math.random() * 0.75
    local y = math.random() * 0.75
    local w = 0.25 + math.random() * (0.75-x)
    local h = 0.25 + math.random() * (0.75-y)
    adjustwin(x, y, w, h)()
end)
