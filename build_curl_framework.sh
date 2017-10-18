#!/bin/bash
DEFAULT_iOS_SDK_VERSION=`defaults read $(xcode-select -p)/Platforms/iPhoneOS.platform/version CFBundleShortVersionString`
DTCompiler=`defaults read $(xcode-select -p)/../info DTCompiler`
DTPlatformBuild=`defaults read $(xcode-select -p)/../info DTPlatformBuild`
DTSDKBuild=`defaults read $(xcode-select -p)/../info DTSDKBuild`
DTXcode=`defaults read $(xcode-select -p)/../info DTXcode`
DTXcodeBuild=`defaults read $(xcode-select -p)/../info DTXcodeBuild`

LIB_BASE_DIR="$(pwd)/curl"
LIB_DEV_DIR="$LIB_BASE_DIR/ios-dev"
LIB_APPSTORE_DIR="$LIB_BASE_DIR/ios-appstore"
LIB_CURL_VERSION="7.56.0"
iOS_SDK_VERSION=$DEFAULT_iOS_SDK_VERSION
OSX_SDK_VERSION="none" #none for iPhoneSimulator
FRAMEWORK_NAME="CURL.framework"
BUNDLE_ID="se.haxx.CURL"
PLIST_FILE="Info.plist"
INCLUDE_FOLDER="include/curl"
SHIMS_FILE="shims.h"
export LIB_CURL_VERSION
export iOS_SDK_VERSION
export OSX_SDK_VERSION
./build_curl

function create_frameowork() {
  folder=$1

  cd $folder

  name="CURL"
  module_folder="Modules"
  os_build_version=$(sw_vers -buildVersion)
  supported_platforms="iPhoneOS"
  framework_folder="$folder/$FRAMEWORK_NAME"
  header_folder="$framework_folder/Headers"
  rm -rf "$folder/$FRAMEWORK_NAME"
  mkdir -p "$FRAMEWORK_NAME"

  cd $FRAMEWORK_NAME

  cp -rf "$folder/$INCLUDE_FOLDER" "$folder/$FRAMEWORK_NAME"
  mv "$folder/$FRAMEWORK_NAME/curl" "$header_folder"

  rm "$header_folder/typecheck-gcc.h"

  cd $framework_folder
  cp "$folder/lib/libcurl.a" $framework_folder
  mv "libcurl.a" $name

  cd $header_folder
  shime_file_path="$header_folder/$SHIMS_FILE"
  cat > $shime_file_path <<EOF
#include "curl.h"
#include "stdcheaders.h"
#include "mprintf.h"

typedef enum {True, False} CBool;

static inline CURLcode curl_setopt_bool(CURL *curl, CURLoption option, CBool yesNo) {
    return curl_easy_setopt(curl, option, yesNo == True ? 1L : 0L);
}

// set options list - CURLOPT_HTTPHEADER, CURLOPT_HTTP200ALIASES, CURLOPT_QUOTE, CURLOPT_TELNETOPTIONS, CURLOPT_MAIL_RCPT, etc.
static inline CURLcode curl_setopt_list(CURL *curl, CURLoption option, struct curl_slist *list) {
    return curl_easy_setopt(curl, option, list);
}

static inline CURLcode curl_setopt_int(CURL *curl, CURLoption option, long data) {
    return curl_easy_setopt(curl, option, data);
}

// const keyword is used so that Swift strings can be passed

static inline CURLcode curl_setopt_string(CURL *curl, CURLoption option, const char *data) {
    return curl_easy_setopt(curl, option, data);
}

static inline CURLcode curl_setopt_read_callbck(CURL *curl, void *userData, size_t (*read_cb) (char *buffer, size_t size, size_t nitems, void *userdata)) {

    CURLcode rc = curl_easy_setopt(curl, CURLOPT_READDATA, userData);
    if  (rc == CURLE_OK) {
        rc = curl_easy_setopt(curl, CURLOPT_READFUNCTION, read_cb);
    }
    return rc;
}

static inline CURLcode curl_setopt_write_callback(CURL *curl, void *userData, curl_write_callback write_cb) {

    CURLcode rc = curl_easy_setopt(curl, CURLOPT_WRITEDATA, userData);
    if  (rc == CURLE_OK) {
        rc = curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    }
    return rc;
}

static inline CURLcode curl_setopt_debug_callback(CURL *curl, void *userData, size_t (*debug_cb) (CURL *curl, curl_infotype infotype, char *info, size_t infoLen, void *contextInfo)) {

    CURLcode rc = curl_easy_setopt(curl, CURLOPT_DEBUGDATA, userData);
    if  (rc == CURLE_OK) {
        rc = curl_easy_setopt(curl, CURLOPT_DEBUGFUNCTION, debug_cb);
    }
    return rc;
}

static inline CURLcode curl_setopt_header_callback(CURL *curl, void *userData, size_t (*header_cb) (char *buffer, size_t size, size_t nmemb, void *userdata)) {

    CURLcode rc = curl_easy_setopt(curl, CURLOPT_HEADERDATA, userData);
    if (rc == CURLE_OK) {
        rc = curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, header_cb);
    }
    return rc;
}

static inline CURLcode curl_getinfo_list(CURL *curl, CURLINFO info, struct curl_slist  *data) {
    return curl_easy_getinfo(curl, info, data);
}

static inline CURLcode curl_getinfo_long(CURL *curl, CURLINFO info, long *data) {
    return curl_easy_getinfo(curl, info, data);
}
EOF
  cd $framework_folder
  mkdir -p "$module_folder"
  module_folder_path="$framework_folder/$module_folder"
  cd $module_folder
  module_file_path="$module_folder_path/module.modulemap"
  cat > $module_file_path <<EOF
framework module CURL {
  umbrella header "shims.h"

  export *
  module * { export * }
}
EOF

  cd $framework_folder
  cat > $PLIST_FILE <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
          <key>BuildMachineOSBuild</key>
          <string>$os_build_version</string>
          <key>CFBundleDevelopmentRegion</key>
          <string>en</string>
          <key>CFBundleExecutable</key>
          <string>$name</string>
          <key>CFBundleIdentifier</key>
          <string>$BUNDLE_ID</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleName</key>
          <string>$name</string>
          <key>CFBundlePackageType</key>
          <string>FMWK</string>
          <key>CFBundleShortVersionString</key>
          <string>$LIB_CURL_VERSION</string>
          <key>CFBundleSignature</key>
          <string>????</string>
          <key>CFBundleSupportedPlatforms</key>
          <array>
          <string>iPhoneOS</string>
          </array>
          <key>CFBundleVersion</key>
          <string>1</string>
          <key>DTCompiler</key>
          <string>$DTCompiler</string>
          <key>DTPlatformBuild</key>
          <string>$DTPlatformBuild</string>
          <key>DTPlatformName</key>
          <string>iphoneos</string>
          <key>DTPlatformVersion</key>
          <string>$iOS_SDK_VERSION</string>
          <key>DTSDKBuild</key>
          <string>$DTSDKBuild</string>
          <key>DTSDKName</key>
          <string>iphoneos$iOS_SDK_VERSION</string>
          <key>DTXcode</key>
          <string>$DTXcode</string>
          <key>DTXcodeBuild</key>
          <string>$DTXcodeBuild</string>
          <key>MinimumOSVersion</key>
          <string>8.0</string>
          <key>UIDeviceFamily</key>
          <array>
          <integer>1</integer>
          <integer>2</integer>
          </array>
</dict>
</plist>
EOF
}

if [ -d "$LIB_DEV_DIR" ]; then
  create_frameowork $LIB_DEV_DIR
fi

if [ -d "$LIB_APPSTORE_DIR" ]; then
  create_frameowork $LIB_APPSTORE_DIR
fi

echo "🎉🎉 Using curl/ios-(dev|appstore)/$FRAMEWORK_NAME now!! "
