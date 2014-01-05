#!/usr/bin/zsh

BASEDIR=/home/lfiles/dev
PKGBUILDSDIR=$BASEDIR/archlinux-PKGBUILDs

pkggroup="$1"

# used to indicate options
# On using makepkg, options to makepkg can be sent, eg "-si --needed --noconfirm"
# On using ccm, following options can be indicated:
#   allnoclean - the chroot is not cleaned before building any package.
#   noclean    - the chroot is cleaned only before building first package.
#   continue   - the chroot is not cleaned only after building the first package. Used to continue a aborted build.
uoptions="$2"

# indicate 'usemakepkg' to build using makepkg, anything else uses ccm
usemakepkg="$3"

# indicate 'nonewchroot' to not recreate the chroot before starting the build. This is only valid if ccm is used.
nonewchroot="$4"

case "$pkggroup" in
    kf5)
        folder="kf5"
        prepackages=("shared-mime-info" "qt5-base" "git")
        packages=(
                'cmake-git'
                'extra-cmake-modules-git' 'kf5-kapidox-git' 'kf5-karchive-git' 'kf5-kcoreaddons-git' 'kf5-polkit-qt-git' 'kf5-kauth-git'
                'kf5-kcodecs-git' 'kf5-kconfig-git' 'kf5-kdoctools-git' 'kf5-kguiaddons-git' 'kf5-kjs-git' 'kf5-ki18n-git'
                'kf5-kwidgetsaddons-git' 'kf5-kconfigwidgets-git' 'kf5-kitemviews-git' 'kf5-kiconthemes-git' 'kf5-kglobalaccel-git'
                'kf5-kcompletion-git' 'kf5-kwindowsystem-git' 'kf5-kcrash-git' 'kf5-kdbusaddons-git' 'kf5-kservice-git' 'kf5-sonnet-git'
                'kf5-ktextwidgets-git' 'kf5-attica-git' 'kf5-kxmlgui-git' 'kf5-kbookmarks-git' 'kf5-kcmutils-git' 'kf5-solid-git'
                'kf5-kjobwidgets-git' 'libdbusmenu-qt5-bzr' 'kf5-knotifications-git' 'kf5-kio-git' 'kf5-kdeclarative-git' 'kf5-kinit-git'
                'kf5-kded-git' 'kf5-kplotting-git' 'kf5-kpty-git' 'kf5-kdesu-git' 'kf5-kwallet-framework-git' 'kf5-kparts-git' 'kf5-kdewebkit-git'
                'kf5-kdesignerplugin-git' 'kf5-kdnssd-framework-git' 'kf5-kemoticons-git' 'kf5-kf5umbrella-git' 'kf5-kidletime-git'
                'kf5-kimageformats-git' 'kf5-kitemmodels-git' 'kf5-kjsembed-git' 'kf5-kmediaplayer-git' 'kf5-kprintutils-git' 'kf5-kross-git'
                'kf5-kunitconversion-git' 'kf5-threadweaver-git' 'kf5-kde4support-git' 'kf5-kfileaudiopreview-git' 'kf5-khtml-git'
                'kf5-knewstuff-git' 'kf5-knotifyconfig-git' 'kf5-frameworkintegration-git' 'kactivities-frameworks-git' 'kf5-akonadi-git'
                'plasma-framework-git' 'kde-workspace-git'
                )
        ;;
    telepathy)
        folder="telepathy-kde"
        prepackages=('kdebase-runtime' 'cmake' 'git' 'automoc4' 'kdepimlibs')
        packages=(
#         'libkpeople-git' 'telepathy-logger-qt-git'
        'telepathy-kde-common-internals-git' 'telepathy-kde-contact-list-git' 'telepathy-kde-filetransfer-handler-git'
                'telepathy-kde-send-file-git' 'telepathy-kde-integration-module-git' 'telepathy-kde-auth-handler-git' 'telepathy-kde-text-ui-git'
                'telepathy-kde-approver-git' 'telepathy-kde-accounts-kcm-git' 'telepathy-kde-desktop-applets-git' 'telepathy-kde-contact-runner-git'
                'telepathy-kde-git-meta')
        ;;
    kte)
        folder="kte-collaborative"
        packages=('libqinfinity-git'
                'kte-collaborative-git')
        ;;
    active)
        folder="telepathy-kde-active"
        packages=('kde-plasma-mobile-git'
                'plasmate-git')
        ;;
    rest)
        folder="-"
        packages=('cower'
                'google-talkplugin'
                'eiskaltdcpp-qt'
                'wxsqlite3')
        cd $PKGBUILDSDIR
        for ((i=1;i<=${#packages[@]};i++));do
            cower -df ${packages[$i]}
        done
        packages=($packages[@] 'guayadeque-svn')
        ;;
    *)  printf "kf5\nkte\ntelepathy\nactive\nrest\n";
        exit 1
        ;;
esac

if [[ "$usemakepkg" != "usemakepkg" ]];then
    if [[ "$nonewchroot" != "nonewchroot" ]];then
        printf "Are you sure you want to nuke chroot? [Y|n]: "
        read inp && [[ "$inp" = "n" ]] && exit 1
        sudo ccm n && sudo ccm c
    fi
    echo "Updating and preinstalling packages..." && \
    sudo arch-nspawn $BASEDIR/archlinux-chroot/root pacman -Syu --needed --noconfirm $prepackages[@] && \
else
    echo -n "Cleaning build dir..." && \
    rm -rf $BASEDIR/build/makepkg/* && \
    find $PKGBUILDSDIR -name '*.gz' -exec rm -rf {} \; && \
    echo "done"
fi

opt="" && [[ "$uoptions" = "continue" ]] && opt="noclean"
for ((i=1;i<=${#packages[@]};i++));do
    if [[ "$usemakepkg" = "usemakepkg" ]];then
        /usr/bin/bash $BASEDIR/makebuild.sh ${packages[$i]} $folder $uoptions usemakepkg || exit 1
    else
        [[ "$uoptions" = "allnoclean" ]] && opt="noclean"
        /usr/bin/bash $BASEDIR/makebuild.sh ${packages[$i]} $folder "$opt"  || exit 1
        [[ "$uoptions" = "noclean" ]] && opt="noclean"
        [[ "$uoptions" = "continue" ]] && opt=""
    fi
done

printf "\nCleaning pkg files..." && \
find $PKGBUILDSDIR -name '*.xz' -exec rm -rf {} \; && \
echo "done"
echo
