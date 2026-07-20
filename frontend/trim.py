from PIL import Image, ImageChops
def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

try:
    im = Image.open('assets/images/onboarding/work.png')
    im = trim(im)
    im.save('assets/images/onboarding/work.png')
    print("Cropped successfully")
except Exception as e:
    print(f"Error: {e}")
