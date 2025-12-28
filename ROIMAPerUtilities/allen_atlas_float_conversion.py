# -*- coding: utf-8 -*-
"""
Created on Sat Dec 27 20:37:35 2025

@author: julia
"""
import simpleITK as sitk

image = sitk.Image([10,10], sitk.sitkVectorFloat32, 5)
image.SetOrigin((3.0, 14.0))
image.SetSpacing((0.5, 2))