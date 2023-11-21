import math

STEP_SIZE = 5
PRECISION = 4

for angle_degrees in range(-89, 90, STEP_SIZE):
    tangent = math.tan(math.radians(angle_degrees))
    ratio = int(round(tangent * 2 ** PRECISION))
    angle_0_360 = (angle_degrees + 360) % 360

    print(f"    end else if (ratio <= {ratio}) begin")
    print(f"      angle = old_xs[0] > 0 ? {(angle_degrees + 360) % 360} : {(angle_degrees + 180) % 360};")