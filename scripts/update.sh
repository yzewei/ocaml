#!/bin/bash
git restore .gitignore Makefile configure.ac runtime/caml/config.h runtime/caml/stack.h
rm -rf asmcomp/loongarch64/ runtime/loongarch64.S testsuite/tools/asmgen_loongarch64.S Makefile.add
# 目标的 .gitignore 文件路径
TARGET_GITIGNORE="$1/.gitignore"
# 目标项目的 Makefile 路径
TARGET_MAKEFILE="$1/Makefile"
ADDITIONAL_FILE="$1/Makefile.add"
# 检查 Makefile 是否存在
if [ ! -f "$TARGET_MAKEFILE" ]; then
  echo "Makefile not found in the target project."
  exit 1
fi

# 检查目标项目是否存在 .gitignore 文件
if [ ! -f "$TARGET_GITIGNORE" ]; then
  echo ".gitignore file not found in the target project."
  exit 1
fi

#其他修改
git apply ./update-config-stack.patch
echo "update configure.ac runtime/caml/config.h runtime/caml/stack.h && add asmcomp/loongarch64/ runtime/loongarch64.S testsuite/tools/asmgen_loongarch64.S"

# 新增的 .gitignore 规则
NEW_ENTRIES=(
  "/asmcomp/loongarch64/CSE.ml"
  "/asmcomp/loongarch64/reload.ml"
  "/asmcomp/loongarch64/scheduling.ml"
)

# 确保 .gitignore 文件中包含 /asmcomp 行
if ! grep -q '/asmcomp' "$TARGET_GITIGNORE"; then
  echo "No /asmcomp entry found in .gitignore. Please ensure /asmcomp exists."
  exit 1
fi

# 找到最后一个 /asmcomp 的行，并在其后添加新条目
for entry in "${NEW_ENTRIES[@]}"; do
  # 将新条目追加到目标 .gitignore 文件中的 /asmcomp 之后
  sed -i "/\/asmcomp/ a $entry" "$TARGET_GITIGNORE"
done

echo "New entries added to the .gitignore file."

# 使用 sed 将内容插入到指定位置
if ! grep -q 'include Makefile.add' "$TARGET_MAKEFILE"; then
  sed -i '/include Makefile.best_binaries/a\
include Makefile.add' "$TARGET_MAKEFILE"
  echo "Modification complete in Makefile."
else
  echo "[ERROR] Modification complete in Makefile failed!!!!!."
fi

# 修改 ARCHES 行，追加 loongarch64
if ! grep -q 'ARCHES=.*loongarch64' "$TARGET_MAKEFILE"; then
  sed -i '/^ARCHES=/s/$/ loongarch64/' "$TARGET_MAKEFILE"
  echo "Added 'loongarch64' to the ARCHES line."
else
  echo "'loongarch64' already present in ARCHES line."
fi

#if ! grep -q 'rm -f stdlib/libcamlrun.a stdlib/libcamlrun.lib' "$TARGET_MAKEFILE"; then
#  echo "Target line not found, skipping."
#else
#  # 在 rm -f stdlib/libcamlrun.a stdlib/libcamlrun.lib 后插入清理命令，保持缩进
#  sed -i "/rm -f stdlib\/libcamlrun.a stdlib\/libcamlrun.lib/a \
#  $(printf '\t')rm -f asmcomp/loongarch64/CSE.ml asmcomp/loongarch64/reload.ml asmcomp/loongarch64/scheduling.ml" "$TARGET_MAKEFILE"
#  echo "Added clean rules for loongarch64 files after 'rm -f stdlib/libcamlrun.a stdlib/libcamlrun.lib'."
#fi

echo "Makefile modification complete."
