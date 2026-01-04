# -*- coding: utf-8 -*-
"""
Created on Sat Dec 27 20:37:35 2025

@author: julia
"""
import SimpleITK as sitk

import matplotlib.pyplot as plt
import matplotlib as mpl

import numpy as np

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

reader.SetFileName("ROIMAPer/atlases/annotation_10_p56.nrrd")
image_p56 = reader.Execute()
p56_coronal, p56_sagittal, p56_coronal_half = slicing(image_p56)
p56_coronal = float_conversion(p56_coronal)
p56_sagittal = float_conversion(p56_sagittal)
p56_coronal_half = float_conversion(p56_coronal_half)

del image_p56

writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Coronal.tif")
writer.Execute(p56_coronal)
writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Coronal_halfbrain.tif")
writer.Execute(p56_coronal_half)
writer.SetFileName("ROIMAPer/atlases/aba_v3_p56-Sagittal.tif")
writer.Execute(p56_sagittal)
del p56_sagittal
del p56_coronal
