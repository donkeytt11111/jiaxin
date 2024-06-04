#!/bin/bash
Harbor_Address=172.16.1.200       #Harbor主机地址
Harbor_User=admin                      #登录Harbor的用户
Harbor_Passwd=Harbor12345              #登录Harbor的用户密码
Images_File=./images.list   # 镜像清单文件
Tar_File=/backup/Harbor-backup/                 #镜像tar包存放路径
set -x
# 获取Harbor中所有的项目（Projects）
Project_List=$(curl -u admin:Harbor12345  -H "Content-Type: application/json" -X GET  https://172.16.1.200/api/v2.0/projects  -k  | python3 -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')

for Project in $Project_List;do
   # 循环获取项目下所有的镜像
    Image_Names=$(curl -u admin:Harbor12345 -H "Content-Type: application/json" -X GET https://172.16.1.200/api/v2.0/projects/$Project/repositories -k | python3 -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')
    for Image in $Image_Names;do
        # 循环获取镜像的版本（tag)
        Image_Tags=$(curl -u admin:Harbor12345  -H "Content-Type: application/json"   -X GET  https://172.16.1.200/v2/$Image/tags/list  -k |  awk -F '"'  '{print $8,$10,$12}')
       for Tag in $Image_Tags;do
            # 格式化输出镜像信息
            echo "$Harbor_Address/$Image:$Tag"   >> harbor-images-`date '+%Y-%m-%d'`.txt
        done
    done
done
Image_tags=$(uniq $Images_File)
for image_tag in $Image_tags;do
    image_Name=$(echo $image_tag | awk -F/ '{print $3}' |  awk -F: '{print $1}')
    image_Lable=$(echo $image_tag | awk -F/ '{print $3}' |  awk -F: '{print $2}')
    #image_Name=$(echo $image_tag | awk -F ' +' '{print $1}')
    #image_Lable=$(echo $image_tag | awk -F ' +' '{print $2}')
    docker pull 172.16.1.200/$image_tag
    docker tag  172.16.1.200/$image_tag $image_tag
    docker save $image_tag  -o $image_Name.tar
    docker rmi  172.16.1.200/$image_tag
    docker rmi  $image_tag
    mv $image_Name.tar  $Tar_File
done
