local time, earth

local template_texture = love.graphics.newImage("texture_template.png")
local shader_source = [[
extern Image planet_texture;
extern Image night_texture;
extern number time;
extern number rotate_angle;
extern number light_angle;
number M_PI = 3.1415926535897932384626433832795;

mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle),
                sin(_angle), cos(_angle));
}


vec4 effect( vec4 color, Image vectors, vec2 vectors_coords, vec2 screen_coords ){
  // Rotate planet
  vec2 rotated_coords = rotate2d(rotate_angle) * (vectors_coords-vec2(0.5));
  rotated_coords += vec2(0.5);

  vec4 vector = Texel(vectors, rotated_coords );

  if (distance(rotated_coords, vec2(0.5, 0.5)) > 0.5) {
    return vector;
  }

  // Retrieve planet texture pixel
  vec2 planet_coords;
  planet_coords.x = (vector.r + vector.g/255 + time)/2;
  planet_coords.y = vector.b + vector.a/255;

  if (planet_coords.x > 1) {
    planet_coords.x =  planet_coords.x - 1;
  }

  // Calculate shadow.
  vec2 light_coords = vec2(0, 0);
  vec2 shadow_coords = vectors_coords;

  shadow_coords -= vec2(0.5);
  light_coords -= vec2(0.5);
  light_coords = rotate2d(light_angle + M_PI/4) * light_coords;
  number shadow = 0;
  shadow = 1-pow(distance(light_coords, shadow_coords)*0.9, 3);
  if (shadow < 0.05) {
    shadow = 0.05;
  }

  vec4 pixel = Texel(planet_texture, planet_coords );

  %s

  return pixel;
}
]]
local mesh_shader = love.graphics.newShader

Planet = setmetatable({}, {
  __call = function(_, options)
    local self =  setmetatable({
      planet_texture = options.planet_texture,
      clouds_texture = options.clouds_texture,
      night_texture = options.night_texture,
      template_texture = template_texture,
      time = 0,
      speed = options.speed or 0.1,
      rotate_angle = options.rotate_angle or 0,
      light_angle = options.light_angle or 0,
      size = template_texture:getHeight()/2,
      atmosphere_color = options.atmosphere_color or {160, 160, 165},
      atmosphere_size = options.atmosphere_size or 24
    }, Planet)
    local planet_shader_source
    if self.night_texture then
      planet_shader_source = shader_source:format[[
        vec4 nightPixel = Texel(night_texture, planet_coords );
        pixel.r *= shadow + (1.0-shadow) * nightPixel.r;
        pixel.g *= shadow + (1.0-shadow) * nightPixel.g;
        pixel.b *= shadow + (1.0-shadow) * nightPixel.b;
      ]]
    else
      planet_shader_source = shader_source:format[[
        pixel.r *= shadow;
        pixel.g *= shadow;
        pixel.b *= shadow;
      ]]
    end
    self.planet_shader = love.graphics.newShader(planet_shader_source)
    self.planet_shader:send("planet_texture", self.planet_texture)
    if self.night_texture then
      self.planet_shader:send("night_texture", self.night_texture)
    end
    self.planet_shader:send("light_angle", self.light_angle)
    self.planet_shader:send("rotate_angle", self.rotate_angle)
    if self.clouds_texture then
      local clouds_shader_source = shader_source:format[[
        pixel.r = 1-pixel.r;
        pixel.g = 1-pixel.g;
        pixel.b = 1-pixel.b;
        pixel.a = pixel.r * shadow;
      ]]
      self.clouds_shader = love.graphics.newShader(clouds_shader_source)
      self.clouds_shader:send("planet_texture", self.clouds_texture)
      self.clouds_shader:send("light_angle", self.light_angle)
      self.clouds_shader:send("rotate_angle", self.rotate_angle)
    end

    return self
  end
})

Planet.__index = Planet

function Planet:update(dt)
  self.time = (self.time + dt * self.speed) % 2
  self.planet_shader:send("time", self.time)
  if self.clouds_shader then
    self.clouds_shader:send("time", self.time)
  end
end

function Planet:render_template()
  love.graphics.draw(self.template_texture, 0, 0)
end

function Planet:render_planet()
  love.graphics.setShader(self.planet_shader)
  self:render_template()
  love.graphics.setShader()
end

function Planet:render_clouds()
  if self.clouds_shader then
    love.graphics.setShader(self.clouds_shader)
    self:render_template()
    love.graphics.setShader()
  end
end

function Planet:render_arc(a, b)
  love.graphics.arc("line", "open", self.size, self.size, self.size,
    -self.light_angle + a, -self.light_angle + b)
end

function Planet:set_atmosphere_color(a)
  love.graphics.setColor(
    self.atmosphere_color[1],
    self.atmosphere_color[2],
    self.atmosphere_color[3], a or 255)
end

function Planet:render_atmosphere()
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(16)
  local n = self.atmosphere_size
  local tail = math.pi/6 -- how long is section of atmosphere that tapers off
  local size = 0.6 -- how big is shadow of atmosphere
  local tau = 2 * math.pi
  for i = n + 3, 3, -1 do
    love.graphics.setLineWidth(i)
    local step = (i - 3) / n
    self:set_atmosphere_color(5)
    self:render_arc(size + tail * step - tau, -(size + tail * step))
    self:set_atmosphere_color(255 * step)
    love.graphics.setLineWidth(1)
    self:render_arc(size + tail * step - tau, size + tail * (step + 1/n) - tau)
    self:render_arc(-(tail * step + size), -(size + tail * (step + 1/n)))
  end
  self:set_atmosphere_color(255)
  love.graphics.setLineWidth(1)
  self:render_arc(tail + size - tau, -(tail + size))
end

function Planet:draw()
  self:render_planet()
  self:render_clouds()
  self:render_atmosphere()
end

function love.load()
  time = 0
  earth = Planet{
    speed = 0.1,
    planet_texture = love.graphics.newImage("texture_earth.png"),
    clouds_texture = love.graphics.newImage("texture_clouds.png"),
    night_texture = love.graphics.newImage("texture_night.png"),
    light_angle = math.pi-math.pi/16,
    rotate_angle = -math.pi/16,
    atmosphere_color = {160, 160, 190},
    atmosphere_size = 36
  }
end

function love.update(dt)
  time = time + dt
  earth:update(dt)
end

function love.draw()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", 0, 0, 800,600)
  love.graphics.push()
  love.graphics.translate(10, 10)
  love.graphics.scale(0.5)
  earth:draw()
  love.graphics.pop()
end
