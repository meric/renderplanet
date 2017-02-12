#! env luajit

local torch = require("torch")
local image = require("image")

local pi = math.pi
local cos = math.cos
local asin = math.asin
local atan = math.atan
local sqrt = math.sqrt


-- Given x, y (normalized between -1 and 1) of a orthographic projection,
-- return longitude. x, y must not be outside of the sphere.
-- See http://mathworld.wolfram.com/OrthographicProjection.html
-- @param x x coordinate normalized between -1 and 1, where -1 is left edge.
-- @param y y coordinate normalized between -1 and 1, where -1 is top edge.
-- @return longitude in radians.
local function longitude(x, y)
  return atan(x/cos(asin(sqrt(x*x + y*y))))
end


-- Given y (normalized between -1 and 1) of a orthographic projection,
-- return latitude. y must not be outside of the sphere.
-- See http://mathworld.wolfram.com/OrthographicProjection.html
-- @param y y coordinate normalized between -1 and 1, where -1 is top edge.
-- @return latitude in radians.
local latitude = asin


-- Given a power of two, generate a template for shader to use to wrap planet
-- texture around. The size of template will be 2^(power of two) + 1.
-- The extra 1 is to take into account the 0 in the middle.
-- @param pot
-- @return tensor The tensor that can be saved as an image.
local function template(pot)
  pot = pot or 2
  local size = 2^pot + 1
  local center = (size-1)/2
  local cs = torch.Tensor(4, size, size)
  local ys = torch.Tensor(4, size, size)
  local xs = torch.Tensor(4, size, size)
  for i, tensor in pairs {cs, ys, xs} do
    for j=1, tensor:size(i), 1 do
      tensor:select(i, j):fill(j-1)
    end
  end
  cs:map2(ys, xs, function(c, y, x)
    local dx, dy = x/center-1.0, y/center-1.0
    if dx * dx + dy * dy <= 1 then
      if c == 0 then
        return longitude(dx, dy)/pi + 0.5
      end
      if c == 1 then
        return ((longitude(dx, dy)*65025/pi + 32512.5) % 255) / 255
      end
      if c == 2 then
        return latitude(dy)/pi + 0.5
      end
      if c == 3 then
        return ((latitude(dy)*65025/pi + 32512.5) % 255) / 255
      end
    end
    return 0
  end)
  return cs
end


image.save("template.png", template(10))
