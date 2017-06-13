#! /bin/bash
# 此脚本为公司版本专用 即 易联融通
packetflag=$1 #出包标识  1为AdHoc模式 0为正式发布模式（自动上传至app store)

svnversion=`svn info |grep 'Revision:'|awk '{print $2}'`
release_date=`date +"%Y-%m-%d"`
PROFILE="All-Distribution"

if [ $packetflag -eq '1' ];then
PROFILE="ad-hoc all"
echo '当前模式为AdHoc模式，输出的安装包为内测版本'
elif [ $packetflag -eq '0' ];then
echo '当前模式为正常发布模式，输出的安装包为App Store提交版本'
PROFILE="distribution_usp"
else
echo '第一个参数不能为空，且只接受1或0， 1代表AhHoc模式 0代表正式发布模式(自动上传至app store)'
exit 1
fi

chmod 777 ./modifyPlist
./modifyPlist 易联融通 ${svnversion} USP

rm -r *.ipa
rm -r *.xcarchive


#解锁钥匙串 此处或需要输入mac当前登录账号的密码
security unlock-keychain

#clean工程
xcodebuild clean -project USP.xcodeproj -configuration Release -alltargets

#清理成功后，生成xcarchive文件
if [ $? -eq 0 ]; then
xcodebuild archive -project USP.xcodeproj -scheme USP -archivePath USP.xcarchive CODE_SIGN_IDENTITY="iPhone Distribution: Hangzhou Commnet Software Technology Co., Ltd. (N4SV9VFF49)"
else
    echo 'xcodebuild clean 执行失败'
    exit 1
fi

#编译成功后打包，将xcarchive文件打包成ipa并且加入相应的许可文件
if [ 1 ]; then
xcodebuild -exportArchive -archivePath USP.xcarchive -exportPath USP -exportFormat ipa -exportProvisioningProfile "${PROFILE}"
else
    echo '生成xcarchive文件失败'
    exit 1
fi

if [ $packetflag -eq '1' ];then
    if [ $? -eq 0 ]; then
        echo '成功生成ipa文件'
        exit 0
    else
        echo '生成ipa文件失败'
        exit 1
    fi
fi

if [ $packetflag -eq '0' ];then
    if [ 1 ]; then
#验证安装包
/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool --validate-app -f USP.ipa -u dev@commnetsoft.com -p Commnetsoft.123 -t ios --output-format xml
    else
        echo '生成ipa文件失败'
        exit 1
    fi
    if [ $? -eq 0 ];then
        echo '开始提交至app store'
#上传至app store
/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool --upload-app -f USP.ipa -u dev@commnetsoft.com -p Commnetsoft.123 -t ios --output-format xml
    else
        echo '验证ipa文件失败'
        exit 1
    fi

    if [ $? -eq 0 ];then
        echo '上传app store成功'
    else
        echo '上传app store失败'
        exit 1
    fi
fi


exit 0







