function a = vecangle180(v1,v2,n)
x = cross(v1,v2);
c = norm(x);
a = atan2d(c,dot(v1,v2));
end