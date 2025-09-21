#!/system/bin/sh



# TIME:20250921




# ==============================================================================
# 脚本名称：move_to_constant_folder.sh
# 功能描述：将指定结构的文件夹移动到预定义的目录

# !!!!!! 主要由于移动解压后的文件，从二级目录移动到一级目录 !!!!!!

# 适用环境：Android系统（兼容Linux）
# 核心逻辑：
#   1. 自动识别脚本所在目录作为操作根目录
#   2. 从根目录下的三位数字文件夹（如000、001）中查找待移动的二级文件夹
#   3. 将找到的文件夹统一移动到常量定义的目标目录
#   4. 生成详细操作日志，记录成功/失败情况
# ==============================================================================



# =============================================
# 常量定义区（可根据实际需求修改以下参数）
# =============================================
# 目标存放目录的固定名称（常量）
TARGET_PARENT="Moved_Folders_35731a7655345cfa0"

# 顶层文件夹匹配规则（三位数字，如000、001、002...）
# 如需修改规则（如两位数字），可改为"[0-9][0-9]"
TOP_LEVEL_PATTERN="[0-9][0-9][0-9]"

# 临时目录名称（用于存储中间文件，脚本结束后自动清理）
TMP_DIR_NAME=".tmp_move"

# 日志文件名称（记录操作全过程）
LOG_FILE_NAME="MoveLog.txt"

# =============================================
# 路径自动识别与初始化
# =============================================
# 自动获取脚本所在路径（兼容不同Shell环境）
# 尝试多种命令获取绝对路径，确保在Android简化Shell中也能工作
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")

# 提取脚本所在目录（作为操作根目录）
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# 验证根目录有效性
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    echo "错误：无法识别脚本所在目录，请将脚本放在有效文件夹中"
    exit 1  # 终止脚本执行（错误码1表示路径无效）
fi
ROOT_DIR="$SCRIPT_DIR"  # 确认根目录为脚本所在目录

# 拼接目标目录完整路径（根目录+常量文件夹名）
DEST_DIR="$ROOT_DIR/$TARGET_PARENT"

# 拼接临时目录和日志文件的完整路径
TMP_DIR="$ROOT_DIR/$TMP_DIR_NAME"
LOG_FILE="$ROOT_DIR/$LOG_FILE_NAME"

# =============================================
# 前置环境检查（确保操作可行性）
# =============================================
echo "=== 文件夹移动操作启动 ==="
echo "脚本所在目录：$ROOT_DIR"
echo "目标存放目录：$DEST_DIR"

# 1. 检查根目录是否有写入权限（创建测试文件验证）
TEST_WRITE_FILE="$ROOT_DIR/.test_script_write_permission.tmp"
touch "$TEST_WRITE_FILE" 2>/dev/null  # 尝试创建测试文件
if [ $? -ne 0 ]; then  # $?为上一条命令的退出码，0表示成功
    echo "错误：脚本所在目录无写入权限，无法执行操作"
    exit 2  # 终止脚本（错误码2表示权限不足）
fi
rm -f "$TEST_WRITE_FILE"  # 清理测试文件（无论成功失败都删除）

# 2. 提前创建目标目录（-p确保父目录存在，忽略已存在的错误）
mkdir -p "$DEST_DIR" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "错误：无法创建目标文件夹 $DEST_DIR（可能无权限或路径无效）"
    exit 3  # 终止脚本（错误码3表示目标目录创建失败）
fi

# =============================================
# 初始化临时目录和日志文件
# =============================================
# 创建临时目录（用于存储待移动文件列表）
mkdir -p "$TMP_DIR" 2>/dev/null || { 
    echo "错误：无法创建临时目录 $TMP_DIR"
    exit 4  # 终止脚本（错误码4表示临时目录创建失败）
}

# 初始化日志文件（覆盖旧日志，写入操作头部信息）
echo "==================== 文件夹移动操作日志 ====================" > "$LOG_FILE"
echo "操作开始时间：$(date +'%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"  # 记录开始时间
echo "脚本完整路径：$SCRIPT_PATH" >> "$LOG_FILE"
echo "操作根目录（脚本所在目录）：$ROOT_DIR" >> "$LOG_FILE"
echo "目标存放目录：$DEST_DIR" >> "$LOG_FILE"
echo "顶层文件夹匹配规则：$TOP_LEVEL_PATTERN" >> "$LOG_FILE"
echo "===========================================================" >> "$LOG_FILE"

# =============================================
# 清理函数（脚本退出时自动执行）
# =============================================
cleanup() {
    # 检查临时目录是否存在，存在则清理
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"/* 2>/dev/null  # 删除临时目录内的所有文件
        rmdir "$TMP_DIR" 2>/dev/null     # 删除空的临时目录
        echo "临时目录已清理：$TMP_DIR" >> "$LOG_FILE"
    fi
    # 记录操作结束时间到日志
    echo " " >> "$LOG_FILE"
    echo "操作结束时间：$(date +'%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
}
# 注册退出信号：无论脚本正常结束还是异常终止（如Ctrl+C），都执行cleanup函数
trap 'cleanup' EXIT

# =============================================
# 步骤1：查找所有符合条件的待移动文件夹
# =============================================
# 创建临时文件存储待移动文件夹路径列表
TARGET_LIST="$TMP_DIR/target_folders.txt"
> "$TARGET_LIST"  # 清空文件（确保列表从空开始）

echo " " >> "$LOG_FILE"
echo "【步骤1：查找待移动文件夹】" >> "$LOG_FILE"
echo "开始遍历根目录下符合规则的顶层文件夹..." >> "$LOG_FILE"

# 遍历根目录下所有符合"两位数字"规则的顶层文件夹
for top_dir in "$ROOT_DIR"/$TOP_LEVEL_PATTERN; do
    # 跳过非目录文件（只处理文件夹）
    if [ ! -d "$top_dir" ]; then
        continue  # 继续下一个循环
    fi
    
    # 提取顶层文件夹名称（用于日志显示，简化输出）
    top_dir_name=$(basename "$top_dir")
    echo "  - 正在检查顶层文件夹：$top_dir_name（完整路径：$top_dir）" >> "$LOG_FILE"
    
    # 遍历当前顶层文件夹下的所有二级目录（这些是待移动的目标）
    for target_dir in "$top_dir"/*; do
        # 只处理目录，跳过文件
        if [ -d "$target_dir" ]; then
            # 提取待移动文件夹的名称
            target_name=$(basename "$target_dir")
            # 将完整路径写入待移动列表
            echo "$target_dir" >> "$TARGET_LIST"
            echo "    → 找到待移动文件夹：$target_name（路径：$target_dir）" >> "$LOG_FILE"
        fi
    done
done

# =============================================
# 检查待移动文件夹数量（避免空操作）
# =============================================
# 统计待移动文件夹总数（通过计数列表文件的行数）
target_count=$(wc -l "$TARGET_LIST" 2>/dev/null | awk '{print $1}')

# 如果没有找到待移动文件夹，友好提示并退出
if [ "$target_count" -eq 0 ]; then
    echo " " >> "$LOG_FILE"
    echo "警告：未找到符合规则的待移动文件夹！" >> "$LOG_FILE"
    echo "规则说明：需在根目录下存在「两位数字命名的顶层文件夹」（如00、01），且其下包含二级文件夹" >> "$LOG_FILE"
    
    # 终端提示用户（便于直接查看）
    echo "⚠️  未找到待移动文件夹！"
    echo "请确认在脚本所在目录下，存在类似00、01的文件夹，且这些文件夹下有需要移动的二级目录"
    echo "详细日志请查看：$LOG_FILE"
    exit 0  # 正常退出（错误码0表示无错误，只是没有待处理内容）
fi

echo " " >> "$LOG_FILE"
echo "【步骤1完成】共找到 $target_count 个待移动文件夹" >> "$LOG_FILE"

# =============================================
# 步骤2：执行文件夹移动操作
# =============================================
echo " " >> "$LOG_FILE"
echo "【步骤2：执行文件夹移动】" >> "$LOG_FILE"
echo "开始将文件夹移动到目标目录：$DEST_DIR" >> "$LOG_FILE"

# 初始化计数变量
move_success=0  # 成功移动的文件夹数量
move_fail=0     # 移动失败的文件夹数量

# 逐行读取待移动文件夹列表，执行移动操作
while read -r target_dir; do
    # 跳过空行或无效目录（防御性处理）
    if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
        continue
    fi
    
    # 提取待移动文件夹的名称（用于显示和拼接目标路径）
    target_name=$(basename "$target_dir")
    # 目标路径：目标目录 + 待移动文件夹名称
    dest_path="$DEST_DIR/$target_name"
    
    # 记录当前处理的文件夹信息到日志
    echo " " >> "$LOG_FILE"
    echo "正在处理文件夹：$target_name" >> "$LOG_FILE"
    echo "  - 原始路径：$target_dir" >> "$LOG_FILE"
    echo "  - 目标路径：$dest_path" >> "$LOG_FILE"
    
    # 检查目标路径是否已存在同名文件/文件夹（避免覆盖）
    if [ -e "$dest_path" ]; then
        echo "  ❌ 移动失败：目标路径已存在同名文件/文件夹（为防止覆盖，已跳过）" >> "$LOG_FILE"
        echo "⚠️  跳过 $target_name：目标目录中已存在同名文件夹"  # 终端提示
        move_fail=$((move_fail + 1))  # 失败计数+1
        continue  # 跳过当前文件夹，处理下一个
    fi
    
    # 执行移动操作（-v：显示详细信息；输出重定向到日志）
    mv -v "$target_dir" "$dest_path" >> "$LOG_FILE" 2>&1
    # 检查移动操作是否成功（$?为0表示成功）
    if [ $? -eq 0 ]; then
        echo "  ✅ 移动成功" >> "$LOG_FILE"
        echo "✅ 已成功移动：$target_name → $DEST_DIR"  # 终端提示成功
        move_success=$((move_success + 1))  # 成功计数+1
    else
        echo "  ❌ 移动失败（具体错误请查看日志）" >> "$LOG_FILE"
        echo "❌ 移动失败：$target_name（详细原因请查看日志）"  # 终端提示失败
        move_fail=$((move_fail + 1))  # 失败计数+1
    fi
done < "$TARGET_LIST"  # 从待移动列表文件中读取内容

# =============================================
# 步骤3：输出操作总结（终端+日志）
# =============================================
# 写入总结到日志
echo " " >> "$LOG_FILE"
echo "===========================================================" >> "$LOG_FILE"
echo "【操作总结】" >> "$LOG_FILE"
echo "总待移动文件夹数量：$target_count" >> "$LOG_FILE"
echo "成功移动数量：$move_success" >> "$LOG_FILE"
echo "移动失败数量：$move_fail" >> "$LOG_FILE"
echo "===========================================================" >> "$LOG_FILE"

# 终端显示总结（方便用户快速查看结果）
echo " "
echo "=== 操作完成总结 ==="
echo "目标存放目录：$DEST_DIR"
echo "总待移动文件夹数：$target_count"
echo "✅ 成功移动：$move_success 个"
echo "❌ 失败移动：$move_fail 个"
echo " "
echo "详细操作日志已保存至：$LOG_FILE"
echo "===================="

# 正常退出脚本
exit 0
