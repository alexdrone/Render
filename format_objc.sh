
#!/bin/bash
format() {
  PATH=$(pwd);
  echo "✓ $PATH";
  /usr/local/bin/clang-format -i *.h &>/dev/null
  /usr/local/bin/clang-format -i *.m &>/dev/null
  /usr/local/bin/clang-format -i *.mm &>/dev/null
  /usr/local/bin/clang-format -i *.c &>/dev/null
}

echo "Running clang-format..."
cd Sources/CoreRenderObjC && format;
cd ../../;
cd Tests/CoreRenderObjCTests && format;
