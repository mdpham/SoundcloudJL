using Images, Colors, FixedPointNumbers

type Collage
  xdim
  ydim
  tilewidth
  data
end

# Initialize a Collage type to be filled
function init_collage(xdim,ydim,tilewidth)
  canvas = Array(RGB{U8}, ydim*tilewidth, xdim*tilewidth)
  return Collage(xdim,ydim,tilewidth,canvas)
end
# Fill a Collage with an image at y,x coordinate
function fill_tile(collage::Collage, y, x, tile::Array)
  xstart = (x-1)*collage.tilewidth + 1
  xend = x*collage.tilewidth
  ystart = (y-1)*collage.tilewidth + 1
  yend = y*collage.tilewidth
  collage.data[ystart:yend, xstart:xend] = tile'
  return collage
end
# Given an array of images (should be Collage.tilewidth length), fills an empty Collage
# Number of images in array should be more than Collage.xdim*Collage.ydim
# If not, repeats tiles (idea: fill with colors once Hilbert path figured out)
function fill_collage(collage::Collage, tiles::Array)
  while collage.xdim*collage.ydim < length(tiles)
    tiles = tiles[1:(collage.xdim*collage.ydim)]
  end
  while length(tiles) < collage.xdim*collage.ydim
    push!(tiles, rand(tiles))
  end
  for idx in 1:length(tiles)
    # Snake pattern through tiles top left to bottom right
    i = rem(idx-1, collage.ydim)+1
    j = div(idx-1, collage.ydim)+1
    collage = fill_tile(collage, i, j, tiles[idx])
  end
  return collage
end

# Given directory from parent directory, return array of image data
# dir: "playlists" or "favorites"
function gettempartwork(dir::AbstractString)
  images = []
  function getdirdata()
    for fl in readdir()
      try
        img = data(convert(Image{RGB}, load(fl)))
        push!(images, img)
      catch
      end
    end
  end
  cd(() -> getdirdata(), dir)
  shuffle!(images)
  return images
end
