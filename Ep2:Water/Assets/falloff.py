import cv2
import numpy as np

img = cv2.imread("heightmap.png")/255

out_img = np.asarray(img)

for x,row in enumerate(img):
    for y,pixel in enumerate(row):
        out_img[x,y] = pixel * min(-abs(x*2/len(img) - 1)**2 + 1 , -abs(y*2/len(row) - 1)**2 + 1) 

cv2.imwrite("hm.png", out_img * 255)
