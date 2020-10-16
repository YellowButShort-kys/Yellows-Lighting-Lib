local yellows_rl = {}
local shapes = require 'Yellows_raylight.HC.shapes'
local blocking_objects = {}
local light_sources = {}
local circle_light
local cone_light

local function ccw (a,b,c) 
    --if a looks at b, is c on the left or on the right? (points)
    local num = ((b[1] - a[1])*(c[2]-a[2]))-((b[2]-a[2])*(c[1]-a[1]))
    return num
end
local function lineLineCollision(lineA,lineB)
    --will check whether lineA crosses lineB. Returns point of collision
    local A = lineA[1] --A,B,C and D are the points that make up the lines
    local B = lineA[2]
    local C = lineB[1]
    local D = lineB[2]
    if ((ccw(A,B,C) * ccw (A,B,D)) < 0) and ((ccw(C,D,A) * ccw(C,D,B)) < 0) then
        return true
    else
        return false
    end
end
  
function yellows_rl.Init()
    circle_light = require "Yellows_raylight.lights.light_round"
    cone_light = require "Yellows_raylight.lights.light_cone"
end

function yellows_rl.CreateCircleLight(x, y, radius)
    assert(type(x)=="number", "X should be a number")
    assert(type(y)=="number", "Y should be a number")
    assert(type(radius)=="number", "Radius should be a number")

    local source = {}
    setmetatable(source, {__index = circle_light})
    source.id = #light_sources
    source.x = x
    source.y = y
    source.radius = radius
    source.col = shapes.newCircleShape(x, y, radius)
    table.insert(light_sources, source)

    yellows_rl.UpdateIntersection()

    return source
end

function yellows_rl.CreateConeLight(x, y, length, base, angle)
    assert(type(x)=="number", "X should be a number")
    assert(type(y)=="number", "Y should be a number")
    assert(type(length)=="number", "Length should be a number")
    assert(type(base)=="number", "Length should be a number")
    assert(type(angle or 0)=="number", "Angle should be a number")

    local source = {}
    setmetatable(source, {__index = cone_light})
    source.id = #light_sources
    source.x = x
    source.y = y
    source.length = length
    source.base = base
    source.angle = angle or 0 * math.pi/180
    source.col = shapes.newPolygonShape(x, y, x - base/2, y - length, x + base/2, y - length)
    source.col:setRotation(angle or 0 * math.pi/180, x, y)
    table.insert(light_sources, source)

    yellows_rl.UpdateIntersection()

    return source
end

function yellows_rl.Remove(id, type)
    if type then
        table.remove(light_sources, id)
    else
        table.remove(blocking_objects, id)
    end
end

function yellows_rl.CreateRectangonalBlocker(x, y, w, h)
    local blocker = shapes.newPolygonShape(x, y, x+w, y, x+w, y+h, x, y+h)
    blocker.polygons = {{x, y}, {x+w, y}, {x+w, y+h}, {x, y+h}}
    blocker.lines = {
        {{x,y}, {x+w, y}},
        {{x+w, y}, {x+w, y+h}},
        {{x+w, y+h}, {x, y+h}},
        {{x, y+h}, {x, y}}
    }
    blocker.id = #blocking_objects

    function blocker:Remove()
        yellows_rl.Remove(self.id, true)
        self = nil
        rl.UpdateIntersection()
    end

    table.insert(blocking_objects, blocker)
    return blocker
end

function yellows_rl.UpdateIntersection()
    for _, source in ipairs(light_sources) do
        local returned = {}
        local x, y, radius = source:GetX(), source:GetY()
        if source.GetRadius then
            radius = source:GetRadius()
        elseif source.GetLength then
            radius = source:GetLength()
        end
        
        for _, blocker in ipairs(blocking_objects) do
            --if source.col:collidesWith(blocker) then
                local prefinal = {}
                local PointOrEnd = true
                local nolinecurrent = {}
                for _, polygons in ipairs(blocker.polygons) do
                    local x1, y1 = unpack(polygons)
                    local switch = true
                    local current = {}

                    if x == x1 then
                        local nx1, nx2 = x1 - 1, x1 + 1
                        local len = math.sqrt(math.pow(x - nx1, 2) + math.pow(y - y1, 2))
                        local cx = nx1 + (nx1 - x) / len * 5
                        local cy = y1 + (y1 - y) / len * 5
                        if blocker:contains(cx, cy) then
                            table.insert(nolinecurrent, x1)
                            table.insert(nolinecurrent, y1)
                            switch = false
                        end

                        len = math.sqrt(math.pow(x - nx2, 2) + math.pow(y - y1, 2))
                        cx = nx2 + (nx2 - x) / len * 5
                        cy = y1 + (y1 - y) / len * 5
                        if blocker:contains(cx, cy) then
                            table.insert(nolinecurrent, x1)
                            table.insert(nolinecurrent, y1)
                            switch = false
                        end
                    elseif y == y1 then
                        local ny1, ny2 = y1 - 1, y1 + 1
                        local len = math.sqrt(math.pow(x - x1, 2) + math.pow(y - ny1, 2))
                        local cx = x1 + (x1 - x) / len * 5
                        local cy = ny1 + (ny1 - y) / len * 5
                        if blocker:contains(cx, cy) then
                            table.insert(nolinecurrent, x1)
                            table.insert(nolinecurrent, y1)
                            switch = false
                        end

                        len = math.sqrt(math.pow(x - x1, 2) + math.pow(y - ny2, 2))
                        cx = x1 + (x1 - x) / len * 5
                        cy = ny2 + (ny2 - y) / len * 5
                        if blocker:contains(cx, cy) then
                            table.insert(nolinecurrent, x1)
                            table.insert(nolinecurrent, y1)
                            switch = false
                        end
                    else
                        local len = math.sqrt(math.pow(x - x1, 2) + math.pow(y - y1, 2))
                        local cx = x1 + (x1 - x) / len * 5
                        local cy = y1 + (y1 - y) / len * 5
                        if blocker:contains(cx, cy) then
                            table.insert(nolinecurrent, x1)
                            table.insert(nolinecurrent, y1)
                            switch = false
                        end
                    end

                    if switch then 
                        for _, line in ipairs(blocker.lines) do
                            if lineLineCollision({{x,y}, polygons}, line) then
                                switch = false
                            end
                        end
                    end

                    if switch then
                        local angle = -math.atan2(y1 - y, x1 - x) + math.pi/2
                        local endx, endy = radius * math.sin(angle) + x, radius * math.cos(angle) + y
                        len = math.sqrt(math.pow(x - endx, 2) + math.pow(y - endy, 2))
                        endx = endx + (endx - x) / len * len * len * len
                        endy = endy + (endy - y) / len * len * len * len

                        current[1] = x1
                        current[2] = y1
                        current[3] = endx
                        current[4] = endy

                        table.insert(prefinal, current)
                    end
                end

                local final = {}
                table.insert(final, nolinecurrent[1])
                table.insert(final, nolinecurrent[2])
                for _, var in ipairs(prefinal) do
                    if PointOrEnd then --looks like shit but who cares
                        table.insert(final, var[1])
                        table.insert(final, var[2])
                        table.insert(final, var[3])
                        table.insert(final, var[4])
                        PointOrEnd = false
                    else 
                        table.insert(final, var[3])
                        table.insert(final, var[4])
                        table.insert(final, var[1])
                        table.insert(final, var[2])
                        PointOrEnd = true
                    end
                end
                table.insert(returned, final)
            --end
        end

        for _, var in ipairs(returned) do
            for i = 1, #var-2, 2 do  --in case if points are duplicated
                if var[i] == var[i+2] and var[i+1] == var[i+3] then
                    table.remove(var, i)
                    table.remove(var, i)
                end
            end
        end

        source:CalcDrawing(returned)
    end
end

function yellows_rl.Draw()
    for _, source in ipairs(light_sources) do
        source:Draw()
    end
end

return yellows_rl