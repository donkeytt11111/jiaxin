#!/bin/bash



# 发送邮件方法
function send_config_files_by_email() {
    project_name=$1

    echo "请输入你部署的项目的名字，英文，若输入错误 请用ctrl+w撤回后重新输入"
    read project_name

    # 定义接收者列表
    recipients=("1553232697@qq.com" "18640549232@163.com" "442283241@qq.com" "2505584859@qq.com" "1223645860@qq.com")

    # 定义要发送的配置文件列表
    config_files=("/root/.kube/config" "/root/.talos/config")

    # 安装msmtp和mailx
    install_deps() {
        if command -v yum &> /dev/null; then
            echo "正在为CentOS/RHEL系统安装必要软件..."
            sudo yum install -y msmtp ca-certificates mailx
        else
            echo "无法识别的包管理器，请手动安装msmtp和mailx。"
        fi
    }

# 配置内容定义
config_addition=$(cat <<'EOF'
# 邮箱
set from=15242422977@139.com

# 使用SMTP发送邮件，需在邮箱设置中允许SMTP发送
set smtp=smtp.139.com

# 邮箱用户名
set smtp-auth-user=15242422977@139.com

# 邮箱授权码
set smtp-auth-password=9565c41108878bd25c00
set smtp-auth=login

# 第二个账户配置
set from=18742423211@163.com
set smtp=smtp.163.com
set smtp-auth-user=18742423211@163.com
set smtp-auth-password=CCEARMNBAJVJHAKQ
EOF
)
# 备份原文件
sudo cp /etc/mail.rc /etc/mail.rc.backup-$(date +%Y%m%d%H%M%S)

# 追加配置
if ! sudo grep -qF 'set from=15242422977@139.com' /etc/mail.rc; then
    echo "$config_addition" | sudo tee -a /etc/mail.rc > /dev/null
    echo "配置已成功追加到 /etc/mail.rc"
else
    echo "部分配置已存在，未进行追加操作以避免重复。"
fi


# email方法
send_email_with_attachment() {
    local attachment=$1
    local subject=$2
    local body=$3
    local recipients=("${@:4}")

    if [ -f "$attachment" ]; then
        echo "正在发送附件到以下邮箱：${recipients[*]}，邮件主题为：$subject..."

        {
            echo -e "$body\n\n邮件包含附件。"
        } | mailx -s "$subject" \
                 -S smtp=smtps://smtp.139.com:465 \
                 -S smtp-auth=login \
                 -S ssl-verify=ignore \
                 -S from="18742423211@139.com" \
                 -a "$attachment" \
                 "${recipients[@]}"

        if [ $? -eq 0 ]; then
            echo "邮件（主题：$subject）成功发送至所有接收者。"
        else
            echo "邮件（主题：$subject）发送失败，请检查配置后重试。"
        fi
    else
        echo "附件文件不存在，跳过发送。"
    fi
}

    # 从控制台动态获取邮箱地址
    echo "请输入额外的收件人邮箱地址: 如果不需要额外发送其他邮箱，请直接回车"
    read additional_recipient

    # 将用户输入的邮箱地址添加到收件人列表
    if [[ -n $additional_recipient ]]; then
        recipients+=("$additional_recipient")
    fi

    # 定义自定义邮件正文内容
    k8s_body="这是Kubernetes配置文件... 项目名为：$project_name"
    talos_body="这是Talos系统配置文件... 项目名为：$project_name"

    # 遍历配置文件列表并发送邮件，同时附带自定义邮件正文
    for config_file in "${config_files[@]}"; do
        case "$config_file" in
            "/root/.kube/config")
                send_email_with_attachment "$config_file" "Kubernetes Config 文件 项目名为：$project_name" "$k8s_body" "${recipients[@]}"
                ;;
            "/root/.talos/config")
                send_email_with_attachment "$config_file" "Talos System Config 文件 项目名为：$project_name" "$talos_body" "${recipients[@]}"
                ;;
            *)
                echo "未知的配置文件：$config_file，跳过发送。"
                ;;
        esac
    done

# 打包并发送目录中的所有文件
zip_and_send() {
    local directory=$1
    local zipfile=$(mktemp).zip
    local tempdir=$(mktemp -d)

    # 检查目录下是否有文件
    if find "$directory" -maxdepth 1 -type f -print0 | xargs -0 ls | grep -q .; then
    #if find "$directory" -maxdepth 1 -type f | grep -q .; then
        cp -r "$directory"/* "$tempdir" && (cd "$tempdir" && zip -r "$zipfile" *) # 修改这里
        if [ $? -eq 0 ]; then
            echo "打包文件成功，准备发送邮件..."
            send_email_with_attachment "$zipfile" "附件来自：$directory" "这是来自目录的打包文件。" "${recipients[@]}"
        else
            echo "打包文件失败：$directory"
        fi
    else
        echo "目录下没有文件，跳过打包。"
        echo "请重新输入一个包含文件的目录。"
        read new_directory
        directory=${new_directory:-$directory}
        zip_and_send "$directory"
    fi

    rm -rf "$tempdir" "$zipfile"
}

# 从控制台动态获取邮箱地址
echo "请输入额外的收件人邮箱地址: 如果不需要额外发送其他邮箱，请直接回车"
read additional_recipient

# 将用户输入的邮箱地址添加到收件人列表
if [[ -n $additional_recipient ]]; then
    recipients+=("$additional_recipient")
fi

# 获取用户输入的目录路径，如果没有输入则使用默认的/opt路径
echo "请输入要打包的目录路径（直接回车使用默认路径 /opt）:"
read directory
directory=${directory:-/opt} # 如果directory为空，则设置为默认值"/opt"

# 检查目录是否存在并打包发送
# 获取用户输入的目录路径，如果直接回车则提示重新输入，直到提供有效路径
while true; do
    echo "请输入要打包的目录路径（直接回车将要求重新输入）:"
    read directory
    if [ -z "$directory" ]; then
        echo "目录路径不能为空，请重新输入。"
    elif [ ! -d "$directory" ]; then
        echo "目录不存在：$directory，请重新输入正确的目录路径。"
    else
        break
    fi
done

# 确保目录非默认且存在后，再执行打包逻辑
if [ "$directory" != "/opt" ]; then
    zip_and_send "$directory"
else
    echo "警告：/opt 是默认路径，已跳过自动打包。如需打包，请明确指定其他非默认目录。"
fi

}

send_config_files_by_email "$1"

exit 0