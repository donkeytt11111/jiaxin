#!/bin/bash
Harbor_Address=172.16.1.200       #Harbor主机地址
Harbor_User=admin                      #登录Harbor的用户
Harbor_Passwd=Harbor12345              #登录Harbor的用户密码
Images_File=./images.list      # 镜像清单文件
Tar_File=/backup/Harbor-backup/                 #镜像tar包存放路径
set -x

# 获取Harbor中所有的项目（Projects）
Project_List=$(curl -u admin:Harbor12345  -H "Content-Type: application/json" -X GET  https://$Harbor_Address/api/v2.0/projects  -k  | python3 -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')

for Project in $Project_List;do
   # 循环获取项目下所有的镜像
    Image_Names=$(curl -u admin:Harbor12345 -H "Content-Type: application/json" -X GET https://$Harbor_Address/api/v2.0/projects/$Project/repositories -k | python3 -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')
    for Image in $Image_Names;do
        # 循环获取镜像的版本（tag)
        Image_Tags=$(curl -u admin:Harbor12345  -H "Content-Type: application/json"   -X GET  https://$Harbor_Address/v2/$Image/tags/list  -k |  awk -F '"'  '{print $8,$10,$12}')
       for Tag in $Image_Tags;do
            # 格式化输出镜像信息
            echo "$Harbor_Address/$Image:$Tag"   >> harbor-images-`date '+%Y-%m-%d'`.txt
        done
    done
done

# 读取Images_File文件中的镜像名称
while read -r image_tag; do
    # 使用awk提取镜像名称和标签，同时处理特殊字符
    image_Name=$(echo $image_tag | awk -F/ '{print $3}' |  awk -F: '{print $1}' | sed 's/\//-/g')
    image_Lable=$(echo $image_tag | awk -F/ '{print $3}' |  awk -F: '{print $2}' | sed 's/:/_/g')

    # 检查image_Name和image_Lable是否为空
    if [ -z "$image_Name" ]; then
        echo "Error: Empty image_Name for $image_tag" >> error_images.txt
        continue
    fi
    if [ -z "$image_Lable" ]; then
        echo "Error: Empty image_Lable for $image_tag" >> error_images.txt
        continue
    fi

    # 创建安全的文件名
    image_save="$image_Name-$image_Lable"

    docker pull $Harbor_Address/$image_tag
    docker tag $Harbor_Address/$image_tag $image_tag
    docker save $image_tag -o "$Tar_File/$image_save.tar"
    docker rmi $Harbor_Address/$image_tag
    docker rmi $image_tag
done < "$Images_File"
