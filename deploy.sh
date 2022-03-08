#!/bin/bash

rm -rf public
hugo
cd public
git init
git add .
git commit -m "update blog"
git remote add origin git@github.com:lambertxiao/lambertxiao.github.io.git
git push origin master -f
