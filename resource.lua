resource = {}

function resource.loadImage(img)
   local imageName = table.concat{"images/", img, ".png"}
   return love.graphics.newImage(imageName)
end

resource.IMAGES = {}
function resource.getImage(img)
   local maybeImage = resource.IMAGES[img]
   if maybeImage then
      return maybeImage
   else
      local image = resource.loadImage(img)
      resource.IMAGES[img] = image
      return image
   end
end

return resource