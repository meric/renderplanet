# [love2d](http://love2d.org) renderplanet demo #

![Earth](/screenshot.png)

This project demonstrate the 2D rendering technique described at
https://habrahabr.ru/post/248381/ (Russian).

I google translated the article to English and followed the instructions
as best as I can, with the difference being I used shaders for the atmosphere
and shadow instead of using a translucent image.

[texture_template.png](/texture_template.png) is orthographic projection encoded into an image.

![template](/texture_template.png)

http://mathworld.wolfram.com/OrthographicProjection.html

It is generated using [generate-template.lua](/generate-template.lua).

All the earth textures are equirectangular projection and the rendering
algorithm assumes this too.

https://en.wikipedia.org/wiki/Equirectangular_projection

You can find more planet texture data from NASA.
