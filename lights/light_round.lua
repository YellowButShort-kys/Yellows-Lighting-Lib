local light_source = {texture = love.graphics.newImage("Yellows_raylight/textures/round.png")}
local rl = require "Yellows_raylight"
local shapes = require 'Yellows_raylight.HC.shapes'

function light_source:SetX(x)
   self.x = x
   self.col:moveTo(x, self.y)
   rl.UpdateIntersection()
end
function light_source:SetY(y)
    self.y = y
    self.col:moveTo(self.x, y)
    rl.UpdateIntersection()
end
function light_source:SetPos(x, y)
    self.x = x
    self.y = y
    self.col:moveTo(x, y)
    rl.UpdateIntersection()
end

function light_source:GetX()
    return self.x
end
function light_source:GetY()
    return self.y
end
function light_source:GetPos()
    return self.x, self.y
end

function light_source:SetRadius(radius)
    self.radius = radius
    rl.UpdateIntersection()
end
function light_source:GetRadius()
    return self.radius
end

function light_source:SetColor(r, g, b, a)
    if type(r) == "table" then
        self.color = r
    else
        self.color = {r, g, b, a}
    end
end
function light_source:GetColor()
    return self.color
end

function light_source:CalcDrawing(polygons)
    self.polygons = polygons
    self.StencilFunc = function()
        for _, var in ipairs(self.polygons) do
            love.graphics.polygon("fill", var)
        end
    end
end

function light_source:Draw()
    love.graphics.stencil(self.StencilFunc, "replace", 1)
    love.graphics.setStencilTest("less", 1)

    love.graphics.setColor(self.color or {1, 1, 1})
    love.graphics.draw(self.texture, self.x-self.radius, self.y-self.radius, self.angle, self.radius*2/self.texture:getWidth())
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setStencilTest()
end

function light_source:Remove()
    rl.Remove(self.id)
    self = nil
    rl.UpdateIntersection()
end

return light_source