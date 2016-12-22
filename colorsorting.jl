# Takes an image and returns the RGB colorspace coordinate that corresponds
# to the color with the highest count in the image (for most images..black)
# Also returns red, blue, green histograms
function rgbbin(image::Array) # Sort pixels of an image into 256x256x256 RGB space histogram
  rgbbins = zeros(256,256,256)
  for px in image
    r = convert(Integer, floor(255red(px))+1)
    g = convert(Integer, floor(255green(px))+1)
    b = convert(Integer, floor(255blue(px))+1)
    rgbbins[r,g,b] += 1
  end
  return rgbbins
end

function rgbchannels(rgbbin::Array) # Returns 3x256 matrix, each entry is
  rchannel = collect(sum(sum(rgbbin,2),3))
  gchannel = collect(sum(sum(rgbbin,1),3))
  bchannel = collect(sum(sum(rgbbin,1),2))
  return [rchannel'; gchannel'; bchannel']
end

function rgbmaxcoord(rgbbin::Array) # Returns RGB index of color with most pixels
  maxcandidate = 0
  iposn = 0; jposn = 0; kposn = 0
  for i in 1:256
    for j in 1:256
      for k in 1:256
        if maxcandidate < rgbbin[i,j,k]
          iposn = i; jposn = j; kposn = k
        end
      end
    end
  end
  return [iposn jposn kposn]
end

function histogram(image::Array)
  bins = rgbbin(image)
  rgbch = rgbchannels(bins)
  rgbcoord = rgbmaxcoord(bins)
end
