# Copyright 2018-2021 Camilo Higuita <milo.h@aol.com>
# Copyright 2018-2021 Nitrux Latinoamericana S.C.
#
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.16)

set(INDEX_VERSION 4.0.3)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

project(index VERSION ${INDEX_VERSION})

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

set(QT_MAJOR_VERSION 6)

set(REQUIRED_QT_VERSION 6.5.2)
set(REQUIRED_KF_VERSION 5.240.0)
set(REQUIRED_MAUI_VERSION 3.0.0)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "index supports Linux builds only.")
endif()

string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" INDEX_HOST_PROCESSOR)
string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" INDEX_TARGET_PROCESSOR)

if(INDEX_HOST_PROCESSOR MATCHES "^(x86_64|amd64)$" AND INDEX_TARGET_PROCESSOR MATCHES "^(x86_64|amd64)$")
    check_c_compiler_flag("-march=x86-64-v3" INDEX_HAS_X86_64_V3_C)
    check_cxx_compiler_flag("-march=x86-64-v3" INDEX_HAS_X86_64_V3_CXX)

    if(INDEX_HAS_X86_64_V3_C AND INDEX_HAS_X86_64_V3_CXX)
        add_compile_options(-march=x86-64-v3)
    endif()
endif()

find_package(ECM ${REQUIRED_KF_VERSION} NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)

include(ECMSetupVersion)
include(ECMSourceVersionControl)
include(ECMFindQmlModule)
include(FeatureSummary)

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED COMPONENTS Core DBus Multimedia Qml Quick QuickControls2 Sql Widgets)
find_package(KF6 ${REQUIRED_KF_VERSION} REQUIRED COMPONENTS I18n CoreAddons Archive KIO)
find_package(MauiKit4 ${REQUIRED_MAUI_VERSION} REQUIRED COMPONENTS FileBrowsing Archiver Documents Terminal TextEditor)

ecm_find_qmlmodule(org.mauikit.terminal)

ecm_find_qmlmodule(org.mauikit.controls)
ecm_find_qmlmodule(org.mauikit.filebrowsing)

if(ECM_SOURCE_UNDER_VERSION_CONTROL)
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    add_definitions(-DGIT_COMMIT_HASH="${GIT_COMMIT_HASH}")
    add_definitions(-DGIT_BRANCH="${GIT_BRANCH}")

else()
    add_definitions(-DGIT_COMMIT_HASH="${INDEX_VERSION}")
    add_definitions(-DGIT_BRANCH="${CMAKE_BUILD_TYPE}")
endif()

ecm_setup_version(${INDEX_VERSION}
    VARIABLE_PREFIX INDEX
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/index_version.h")

if (QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

if (QT_KNOWN_POLICY_QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

add_subdirectory(src)

install(FILES org.kde.index.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES src/data/org.kde.index.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFYRCDIR})

ki18n_install(po)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

qt_finalize_project()
