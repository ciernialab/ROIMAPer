# -*- coding: utf-8 -*-
"""
Created on Sat Dec 27 20:37:35 2025

@author: julia
"""
import SimpleITK as sitk

import matplotlib.pyplot as plt
import matplotlib as mpl

import numpy as np

reader = sitk.ImageFileReader()
reader.SetFileName("ROIMAPer/atlases/annotation_10.nrrd")
image_adult = reader.Execute()

reader.SetFileName("ROIMAPer/atlases/annotation_10_p56.nrrd")
image_p56 = reader.Execute()

def float_conversion(image):
    
    #turn every pixel into its modulo 10000
    pixels = sitk.GetArrayFromImage(image)
    replaced_pixels = pixels % 10000
    replaced_image = sitk.GetImageFromArray(replaced_pixels)
    return replaced_image

image_adult = float_conversion(image_adult)

image_p56 = float_conversion(image_p56)

def slicing(image):
    #first is width, second is height, third is depth
    #default orientation is sagittal
    coronal = image[::10,:,:]
    #now flip the coronal version
    sagittal = image[:,:,::10]
    return coronal, sagittal
adult_coronal, adult_sagittal = slicing(image_adult)
p56_coronal, p56_sagittal = slicing(image_p56)


writer = sitk.ImageFileWriter()
writer.SetFileName("ROIMAPer/atlases/adult_coronal.nrrd")
writer.Execute(adult_coronal)
writer.SetFileName("ROIMAPer/atlases/adult_sagittal.nrrd")
writer.Execute(adult_sagittal)
writer.SetFileName("ROIMAPer/atlases/p56_coronal.nrrd")
writer.Execute(p56_coronal)
writer.SetFileName("ROIMAPer/atlases/p56_sagittal.nrrd")
writer.Execute(p56_sagittal)
