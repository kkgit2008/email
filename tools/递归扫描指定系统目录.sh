#!/system/bin/sh





# TIME:20250921




# 功能：快速扫描指定目录，生成HTML树形报告，支持目录展开/折叠



# 指定扫描目录
SCAN_TARGET_DIR="/system"

# 指定扫描最大深度(值越大，扫描时间越长)
MAX_DEPTH=2

# 结果文件存放位置(尽量不使用公共文件夹)
SCRIPT_DIR="/sdcard/d1d8cd98fa0b0b204e98/scan_result"

mkdir -p "$SCRIPT_DIR"
[ -z "$SCRIPT_DIR" ] && SCRIPT_DIR="/storage/emulated/0/Download"

# 结果文件名称（含时间戳防重复）
RESULT_FILE="$SCRIPT_DIR/System_Fast_Scan_$(date +'%H%M%S').html"

TMP_DIR="$SCRIPT_DIR"
export TMPDIR="$TMP_DIR"

# 检查目标目录是否存在
if [ ! -d "$SCAN_TARGET_DIR" ]; then
    echo "错误：$SCAN_TARGET_DIR 目录不存在" >&2
    exit 1
fi

# 清空结果文件（准备写入新内容）
> "$RESULT_FILE"

# 递归生成目录树HTML（核心函数）
# 参数1：当前目录路径；参数2：HTML缩进前缀；参数3：当前深度；参数4：父目录ID
generate_directory_html() {
    local dir="$1"
    local prefix="$2"
    local current_depth="$3"
    local parent_id="$4"
    local item_index=0  # 用于生成子项目唯一ID的计数器

    # 超过最大深度时显示省略信息
    if [ "$current_depth" -ge "$MAX_DEPTH" ]; then
        echo "${prefix}<div class='tree-item'>" >> "$RESULT_FILE"
        echo "${prefix}  <div class='w-6'></div>" >> "$RESULT_FILE"
        echo "${prefix}  <div>📁</div>" >> "$RESULT_FILE"
        echo "${prefix}  <div class='flex-1 text-gray-500'>...（已限制深度，未继续扫描）</div>" >> "$RESULT_FILE"
        echo "${prefix}</div>" >> "$RESULT_FILE"
        return
    fi

    # 遍历目录所有项目（含隐藏文件，排除.和..）
    for item in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
        [ ! -e "$item" ] && continue  # 跳过不存在的项目
        item_index=$((item_index + 1))
        local base_name=$(basename "$item")
        local size="未知"
        local is_dir=false
        # 生成唯一ID（父ID+计数器，确保子目录可单独控制）
        local item_id="${parent_id}_item${item_index}"
        local children_id="${item_id}_children"

        # 获取项目大小（目录用du，文件标记为"文件"）
        if [ -d "$item" ]; then
            size=$(du -sh "$item" 2>/dev/null | cut -f1)
            is_dir=true
        else
            size="文件"
        fi

        # 写入目录/文件项HTML
        echo "${prefix}<div class='tree-item'>" >> "$RESULT_FILE"
        if [ "$is_dir" = true ]; then
            # 目录：添加展开/折叠箭头（绑定切换函数）
            echo "${prefix}  <div class='icon-btn expand-arrow' onclick='toggleNode(\"${children_id}\", this)'>" >> "$RESULT_FILE"
            echo "${prefix}    <span class='text-gray-500'>▶</span>" >> "$RESULT_FILE"  # 初始折叠（右箭头）
            echo "${prefix}  </div>" >> "$RESULT_FILE"
            echo "${prefix}  <div>📂</div>" >> "$RESULT_FILE"
        else
            # 文件：无箭头，留空占位
            echo "${prefix}  <div class='w-6'></div>" >> "$RESULT_FILE"
            echo "${prefix}  <div>📄</div>" >> "$RESULT_FILE"
        fi
        # 显示名称和大小
        echo "${prefix}  <div class='flex-1'><span class='font-medium'>${base_name}</span> <span class='text-gray-500 text-sm'>(${size})</span></div>" >> "$RESULT_FILE"
        echo "${prefix}</div>" >> "$RESULT_FILE"

        # 递归处理子目录（初始隐藏）
        if [ "$is_dir" = true ]; then
            local new_prefix="${prefix}  "
            echo "${prefix}<div id='${children_id}' class='tree-children tree-line' style='display:none;'>" >> "$RESULT_FILE"
            generate_directory_html "$item" "$new_prefix" $((current_depth + 1)) "$item_id"
            echo "${prefix}</div>" >> "$RESULT_FILE"
        fi
    done
}

# 写入HTML头部（内联样式）
cat << EOF >> "$RESULT_FILE"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>系统目录结构 - 扫描结果</title>
    <style>
        /* 基础样式 */
        body { background: #f9fafb; font-family: monospace; color: #1f2937; margin: 0; padding: 0; }
        .container { max-width: 1200px; margin: 0 auto; padding: 0 1rem; }
        header { background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); padding: 1rem; position: sticky; top: 0; z-index: 10; }
        h1 { font-size: 1.5rem; color: #2563eb; margin: 0 0 1rem 0; display: flex; align-items: center; }
        h2 { font-size: 1.2rem; color: #1f2937; margin: 0 0 0.5rem 0; display: flex; align-items: center; }
        main { padding: 1.5rem 0; }
        .card { background: white; border-radius: 0.5rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; }
        footer { background: white; box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); padding: 1rem; text-align: center; color: #6b7280; font-size: 0.875rem; margin-top: 2rem; }

        /* 树形结构样式 */
        .tree-item { display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem 0; }
        .tree-item:hover { background: #f3f4f6; border-radius: 0.25rem; }
        .tree-line { border-left: 2px solid #e5e7eb; margin-left: 0.5rem; padding-left: 1rem; }
        .w-6 { width: 1.5rem; height: 1.5rem; }
        .icon-btn { cursor: pointer; width: 1.5rem; height: 1.5rem; display: flex; align-items: center; justify-content: center; border-radius: 0.25rem; }
        .icon-btn:hover { background: #e5e7eb; }
        .flex-1 { flex: 1; }
        .text-gray-500 { color: #6b7280; }
        .text-sm { font-size: 0.875rem; }
        .font-medium { font-weight: 500; }
        .mb-4 { margin-bottom: 1rem; }
        .mt-1 { margin-top: 0.25rem; }
        .flex { display: flex; }
        .flex-wrap { flex-wrap: wrap; }
        .gap-4 { gap: 1rem; }
        .items-center { align-items: center; }
        .ml-auto { margin-left: auto; }
        .p-1 { padding: 0.25rem; }
        .bg-gray-100 { background: #f3f4f6; }
        .rounded { border-radius: 0.25rem; }
        .text-red { color: #dc2626; }
    </style>
</head>
<body>
<header>
  <div class="container">
    <h1>📂 系统目录结构扫描结果<span class="text-red">---扫描意外终止，需重新扫描</span></h1>
    <div class="flex flex-wrap gap-4 items-center text-sm">
      <div><span class="inline-block w-3 h-3 bg-blue-500 rounded mr-1"></span>目录 (📂)</div>
      <div><span class="inline-block w-3 h-3 bg-gray-400 rounded mr-1"></span>文件 (📄)</div>
      <button id="expand-all" class="ml-auto icon-btn">➕</button>
      <button id="collapse-all" class="icon-btn">➖</button>
    </div>
  </div>
</header>

<main class="container">
    <div class="card">
        <div class="mb-4 text-sm text-gray-500">
            <p>点击目录前的箭头展开/折叠子目录（最大深度：$MAX_DEPTH层）</p>
            <p class="mt-1">扫描路径：$SCAN_TARGET_DIR</p>
        </div>
        
        <div id="directory-tree" class="tree-root">
EOF

# 启动扫描（记录时间）
echo "正在快速扫描 $SCAN_TARGET_DIR 目录(最大深度$MAX_DEPTH层，约3秒-30分钟) .."
start_time=$(date +%s)

# 生成根目录HTML（初始展开）
root_children_id="root_children"
printf "    <div class='tree-item'>" >> "$RESULT_FILE"
printf "      <div class='icon-btn expand-arrow' onclick='toggleNode(\"${root_children_id}\", this)'>" >> "$RESULT_FILE"
printf "        <span class='text-gray-500'>▼</span>" >> "$RESULT_FILE"  # 根目录初始展开（下箭头）
printf "      </div>" >> "$RESULT_FILE"
printf "      <div>📂</div>" >> "$RESULT_FILE"
printf "      <div class='flex-1'><span class='font-medium'>$SCAN_TARGET_DIR</span> <span class='text-gray-500 text-sm'>$(du -sh "$SCAN_TARGET_DIR" 2>/dev/null | cut -f1)</span></div>" >> "$RESULT_FILE"
printf "    </div>" >> "$RESULT_FILE"
# 根目录子容器（初始显示）
printf "    <div id='${root_children_id}' class='tree-children tree-line' style='display:block;'>" >> "$RESULT_FILE"
generate_directory_html "$SCAN_TARGET_DIR" "    " 0 "root"
printf "    </div>" >> "$RESULT_FILE"

# 计算扫描耗时
end_time=$(date +%s)
scan_duration=$((end_time - start_time))

# 写入HTML尾部与JS（控制展开/折叠）
cat << EOF >> "$RESULT_FILE"
        </div>
    </div>
    
    <div class="card">
        <h2>ℹ️ 扫描信息</h2>
        <div class="text-sm text-gray-500">
            <p>结果文件：<code class="bg-gray-100 p-1 rounded">$RESULT_FILE</code></p>
            <p>扫描时间：$(date +'%Y%m%d %H:%M:%S')</p>
            <p>耗时：${scan_duration}秒 | 最大深度：$MAX_DEPTH层</p>
        </div>
    </div>
</main>

<footer>
    <div class="container">系统目录扫描工具 &copy; $(date +'%Y')</div>
</footer>

<script>
    // 单个目录切换：展开/折叠
    function toggleNode(childrenId, arrowElement) {
        const container = document.getElementById(childrenId);
        const arrow = arrowElement.querySelector('span');
        if (!container || !arrow) return;
        if (container.style.display === 'none') {
            container.style.display = 'block';
            arrow.textContent = '▼';
        } else {
            container.style.display = 'none';
            arrow.textContent = '▶';
        }
    }

    // 全部展开
    document.getElementById('expand-all').onclick = function() {
        document.querySelectorAll('.tree-children').forEach(c => c.style.display = 'block');
        document.querySelectorAll('.expand-arrow span').forEach(s => s.textContent = '▼');
    };

    // 全部折叠（保留根目录展开）
    document.getElementById('collapse-all').onclick = function() {
        document.querySelectorAll('.tree-children').forEach(c => c.style.display = 'none');
        document.querySelectorAll('.expand-arrow span').forEach(s => s.textContent = '▶');
        const root = document.getElementById('root_children');
        const rootArrow = document.querySelector('.tree-root .expand-arrow span');
        if (root) root.style.display = 'block';
        if (rootArrow) rootArrow.textContent = '▼';
    };
</script>
</body>
</html>
EOF

# 扫描完成提示
echo "扫描完成！结果文件：$RESULT_FILE"

# 扫描完成后，修改HTML标题
sed -i 's/---扫描意外终止，需重新扫描/ /' "$RESULT_FILE"

exit 0
