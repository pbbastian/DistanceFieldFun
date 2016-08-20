# Fun with Distance Fields
I'm experimenting with doing various things with distance fields. Currently it's very rudimentary and not very efficient.

I've implemented a cube and a sphere as an image effect. The scene consists of the cube at the origin with the sphere positioned with origin at one of the upper corners of the cube.

The algorithm used for tracing is the basic sphere tracing algorithm. I've made the optimization of increasing the allowed distance from the surface `eps` as the iterations go up. This allows for the maximum number of iterations to be 25 rather than 40 for the current scene. The value starts at 0.01 and increases linearly to 0.1.

![Rendering of scene](http://i.imgur.com/OOXeT2q.png)
