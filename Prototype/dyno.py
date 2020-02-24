##import cv2
##import numpy as np
##re_img1 = cv2.imread('Webp.net.jpg')
##b, g, r = cv2.split(re_img1)
##x_ar=[]
##y_ar=[]
##for x in range(len(b)):
##    for y in range(len(b[0])):
##        if b[x][y]<50:
##            #print (x,","),
##            x_ar.append("6'd"+str(x))
##            y_ar.append("6'd"+str(y))
##        #else:
##        #    print (x,","),
##    #if b[x]=0 :
##        
###print (x_ar)
###print (y_ar)
##for i in range(len(y_ar)):
##    print ("(hc == playerPosX +",x_ar[i]," && vc == playerPosY +",y_ar[i],") || ",end = '')


import numpy as np
import matplotlib.pyplot as plt
from PIL import Image

fname = 'Webp.net.jpg'
image = Image.open(fname).convert("L")
arr = np.asarray(image)
plt.imshow(arr, cmap='binary', vmin=0, vmax=255)
plt.show()

##from PIL import Image 
##image_file = Image.open("Webp.net.jpg") # open colour image
##image_file = image_file.convert('1') # convert image to black and white
##image_file.save('result.png')
##arr = np.asarray(image_file)
##plt.imshow(arr, cmap='gray', vmin=0, vmax=255)
##plt.show()
