# -*- coding: utf-8 -*-
"""
Created on Sat Dec 27 20:37:35 2025

@author: julia
"""
import SimpleITK as sitk
import numpy as np
import os
import tempfile
import re
#%%Defining functions
def float_conversion(image):
    
    #turn every pixel into its modulo 100000
    pixels = sitk.GetArrayFromImage(image)
    pixels = pixels.astype(int)
    replaced_pixels = pixels % 100000
    replaced_image = sitk.GetImageFromArray(replaced_pixels)
    #change datatype to 32 bit float so it can be saved as tif
    replaced_image = sitk.Cast(replaced_image, sitk.sitkFloat32)
    return replaced_image

def slicing(image):
    #first is width, second is height, third is depth
    #default orientation is sagittal
    coronal = image[3::10,:,:]
    #now flip the coronal version
    coronal = sitk.PermuteAxes(coronal, order = [2,1,0])
    #cut x axis in half for halfbrain
    coronal_half = coronal[570:1140,:,:]
    #use 20 um spacing for sagittal
    sagittal = image[:,:,:570:20]
    return coronal, sagittal, coronal_half

def dev_mouse_slicing(image, start, end, steps):
    #first is width, second is height, third is depth
    #use 20 um spacing for sagittal
    sagittal = image[:,:,start:end:steps]
    return sagittal

def read_raw(
    binary_file_name,
    sitk_pixel_type,
    image_spacing=None,
    image_origin=None,
    big_endian=False,
):
    """
    Read a raw binary scalar image.

    Parameters
    ----------
    binary_file_name (str): Raw, binary image file content.
    image_size (tuple like): Size of image (e.g. [2048,2048])
    sitk_pixel_type (SimpleITK pixel type: Pixel type of data (e.g.
        sitk.sitkUInt16).
    image_spacing (tuple like): Optional image spacing, if none given assumed
        to be [1]*dim.
    image_origin (tuple like): Optional image origin, if none given assumed to
        be [0]*dim.
    big_endian (bool): Optional byte order indicator, if True big endian, else
        little endian.

    Returns
    -------
    SimpleITK image or None if fails.
    """

    pixel_dict = {
        sitk.sitkUInt8: "MET_UCHAR",
        sitk.sitkInt8: "MET_CHAR",
        sitk.sitkUInt16: "MET_USHORT",
        sitk.sitkInt16: "MET_SHORT",
        sitk.sitkUInt32: "MET_UINT",
        sitk.sitkInt32: "MET_INT",
        sitk.sitkUInt64: "MET_ULONG_LONG",
        sitk.sitkInt64: "MET_LONG_LONG",
        sitk.sitkFloat32: "MET_FLOAT",
        sitk.sitkFloat64: "MET_DOUBLE",
    }
    direction_cosine = [
        "1 0 0 1",
        "1 0 0 0 1 0 0 0 1",
        "1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1",
    ]
    
    mhd_file_path = binary_file_name.replace(".raw", ".mhd")
    mhd_file = open(mhd_file_path)
    mhd_content = mhd_file.read()
    pattern = re.compile(r"(?<=DimSize\s=\s)([0-9]|\s)+(?=\n)")
    image_size_string = pattern.search(mhd_content).group()
    image_size = list(map(int,image_size_string.split(" ")))
    dim = len(image_size)
    header = [
        "ObjectType = Image\n".encode(),
        (f"NDims = {dim}\n").encode(),
        ("DimSize = " + " ".join([str(v) for v in image_size]) + "\n").encode(),
        (
            "ElementSpacing = "
            + (
                " ".join([str(v) for v in image_spacing])
                if image_spacing
                else " ".join(["1"] * dim)
            )
            + "\n"
        ).encode(),
        (
            "Offset = "
            + (
                " ".join([str(v) for v in image_origin])
                if image_origin
                else " ".join(["0"] * dim) + "\n"
            )
        ).encode(),
        ("TransformMatrix = " + direction_cosine[dim - 2] + "\n").encode(),
        ("ElementType = " + pixel_dict[sitk_pixel_type] + "\n").encode(),
        "BinaryData = True\n".encode(),
        ("BinaryDataByteOrderMSB = " + str(big_endian) + "\n").encode(),
        # ElementDataFile must be the last entry in the header
        ("ElementDataFile = " + os.path.abspath(binary_file_name) + "\n").encode(),
    ]
    fp = tempfile.NamedTemporaryFile(suffix=".mhd", delete=False)

    print(header)

    # Not using the tempfile with a context manager and auto-delete
    # because on windows we can't open the file a second time for ReadImage.
    fp.writelines(header)
    fp.close()
    img = sitk.ReadImage(fp.name)
    os.remove(fp.name)
    return img
#%%adult mice
reader = sitk.ImageFileReader()
reader.SetFileName("ROIMAPer/atlases/annotation_10.nrrd")
image_adult = reader.Execute()
adult_coronal, adult_sagittal, adult_coronal_half = slicing(image_adult)
del image_adult
adult_coronal = float_conversion(adult_coronal)
adult_sagittal = float_conversion(adult_sagittal)
adult_coronal_half = float_conversion(adult_coronal_half)

writer = sitk.ImageFileWriter()
writer.UseCompressionOn()
writer.SetImageIO("TIFFImageIO")
#deflate is lossless
writer.SetCompressor("Deflate")
writer.SetFileName("ROIMAPer/atlases/aba_v3_adult-Coronal.tif")
writer.Execute(adult_coronal)
writer.SetFileName("ROIMAPer/atlases/aba_v3_adult-Coronal_halfbrain.tif")
writer.Execute(adult_coronal_half)
writer.SetFileName("ROIMAPer/atlases/aba_v3_adult-Sagittal.tif")
writer.Execute(adult_sagittal)

del adult_sagittal
del adult_coronal

#%%p56 mice
reader = sitk.ImageFileReader()
reader.SetFileName("ROIMAPer/atlases/annotation_10_p56.nrrd")
image_p56 = reader.Execute()
p56_coronal, p56_sagittal, p56_coronal_half = slicing(image_p56)
p56_coronal = float_conversion(p56_coronal)
p56_sagittal = float_conversion(p56_sagittal)
p56_coronal_half = float_conversion(p56_coronal_half)

del image_p56

writer = sitk.ImageFileWriter()
writer.UseCompressionOn()
writer.SetImageIO("TIFFImageIO")
#deflate is lossless
writer.SetCompressor("Deflate")
writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Coronal.tif")
writer.Execute(p56_coronal)
writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Coronal_halfbrain.tif")
writer.Execute(p56_coronal_half)
writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Sagittal.tif")
writer.Execute(p56_sagittal)
del p56_sagittal
del p56_coronal

#%%developing mouse

writer = sitk.ImageFileWriter()
writer.UseCompressionOn()
writer.SetImageIO("TIFFImageIO")
#deflate is lossless

writer.SetCompressor("Deflate")
dev_mouse_age_list = ["E11pt5", 
                      "E13pt5", 
                      "E15pt5", 
                      "E16pt5", 
                      "E18pt5", 
                      "P4", 
                      "P14",
                      "P28"]
dev_mouse_images = []
for age in range(0,len(dev_mouse_age_list)):
    temp_image = read_raw(
        binary_file_name="ROIMAPer/atlases/" + dev_mouse_age_list[age] + "/annotation.raw",
        sitk_pixel_type=sitk.sitkUInt32
    )
    dev_mouse_images.append(float_conversion(temp_image))


e11pt5_sagittal = dev_mouse_slicing(dev_mouse_images[0],
                                    18,
                                    82,
                                    1)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-e11pt5.tif")
writer.Execute(e11pt5_sagittal)
e13pt5_sagittal = dev_mouse_slicing(dev_mouse_images[1],
                                    107,
                                    172,
                                    1)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-e13pt5.tif")
writer.Execute(e13pt5_sagittal)
e15pt5_sagittal = dev_mouse_slicing(dev_mouse_images[2],
                                    98,
                                    189,
                                    1)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-e15pt5.tif")
writer.Execute(e15pt5_sagittal)

e16pt5_sagittal = dev_mouse_slicing(dev_mouse_images[3],
                                    98,
                                    189,
                                    1)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-e16pt5.tif")
writer.Execute(e16pt5_sagittal)

e18pt5_sagittal = dev_mouse_slicing(dev_mouse_images[4],
                                    37,
                                    148,
                                    1)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-e18pt5.tif")
writer.Execute(e18pt5_sagittal)

p4_sagittal = dev_mouse_slicing(dev_mouse_images[5],
                                    37,
                                    197,
                                    2)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-p4.tif")
writer.Execute(p4_sagittal)

p14_sagittal = dev_mouse_slicing(dev_mouse_images[6],
                                    13,
                                    196,
                                    2)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-p14.tif")
writer.Execute(p14_sagittal)

p28_sagittal = dev_mouse_slicing(dev_mouse_images[7],
                                    42,
                                    217,
                                    2)

writer.SetFileName("ROIMAPer/atlases/aba_v3_devmouse-p28.tif")
writer.Execute(p28_sagittal)
