project('index', 'cpp', version: '4.0.5', meson_version: '>=1.12.0', default_options: ['cpp_std=c++17', 'buildtype=release'])
qt6 = import('qt6')
cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'gcc' and cpp_compiler.has_argument('-Wno-sfinae-incomplete')
    add_project_arguments('-Wno-sfinae-incomplete', language: 'cpp')
endif
qt = dependency('qt6', version: '>=6.9', modules: ['Core', 'DBus', 'Multimedia', 'Qml', 'Quick', 'QuickControls2', 'Sql', 'Widgets'])
kf6_core = dependency('KF6CoreAddons', version: '>=6.13')
kf6_i18n = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KI18n'),
    dependencies: [cpp_compiler.find_library('KF6I18n'), cpp_compiler.find_library('KF6I18nQml')],
)
kf6_archive = dependency('KF6Archive', version: '>=6.13')
kf6_kio = declare_dependency(
    include_directories: include_directories(
        get_option('prefix') / 'include' / 'KF6' / 'KIO',
        get_option('prefix') / 'include' / 'KF6' / 'KIOCore',
        get_option('prefix') / 'include' / 'KF6' / 'KIOFileWidgets',
    ),
    dependencies: [cpp_compiler.find_library('KF6KIOCore'), cpp_compiler.find_library('KF6KIOFileWidgets')],
)
mauikit = dependency('MauiKit4', version: '>=4.0.5')
archiver = dependency('MauiKitArchiver4', version: '>=4.0.5')
documents = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'MauiKit4' / 'Documents'),
    dependencies: [cpp_compiler.find_library('MauiKitDocuments4')],
)
filebrowsing = dependency('MauiKitFileBrowsing4', version: '>=4.0.5')
terminal = dependency('MauiKitTerminal4', version: '>=4.0.5')
texteditor = dependency('MauiKitTextEditor4', version: '>=4.0.5')
cpp_args = []
if host_machine.cpu_family() == 'x86_64'
    cpp_args += ['-march=x86-64-v3']
endif
index_version = configure_file(
    input: 'meson-content.in',
    output: 'index_version.h',
    configuration: {'CONTENT': ('''#pragma once
#define INDEX_VERSION_STRING "4.0.5"
#define GIT_BRANCH "Stable"
#define GIT_COMMIT_HASH "4.0.5"
''')}
)
index_includes = include_directories('src')
dbus_cpp2xml = find_program('qdbuscpp2xml')
dbus_xml2cpp = find_program('qdbusxml2cpp')
dbus_xml = custom_target('index-dbus-xml', input: 'src/index_dbus.h', output: 'org.kde.Index.xml', command: [dbus_cpp2xml, '-o', '@OUTPUT@', '@INPUT@'])
dbus_adaptor = custom_target('index-dbus-adaptor', input: dbus_xml, output: ['indexadaptor.cpp', 'indexadaptor.h'], command: [dbus_xml2cpp, '-a', 'indexadaptor', '@INPUT@'])
dbus_interface = custom_target('index-dbus-interface', input: dbus_xml, output: ['indexinterface.cpp', 'indexinterface.h'], command: [dbus_xml2cpp, '-p', 'indexinterface', '@INPUT@'])
index_sources = ['src/main.cpp', 'src/index.cpp', 'src/controllers/filepreviewer.cpp', 'src/controllers/dirinfo.cpp', 'src/controllers/folderconfig.cpp', 'src/controllers/sessionmanager.cpp', 'src/controllers/fileproperties.cpp', 'src/controllers/patharrowbackground.cpp', 'src/models/recentfilesmodel.cpp', 'src/models/pathlist.cpp', 'src/models/storagemodel.cpp']
qt_sources = qt6.preprocess(qresources: ['src/data/data.qrc', 'src/index_assets.qrc', 'src/qml.qrc'], moc_headers: ['src/index.h', 'src/controllers/filepreviewer.h', 'src/controllers/dirinfo.h', 'src/controllers/folderconfig.h', 'src/controllers/sessionmanager.h', 'src/controllers/fileproperties.h', 'src/controllers/patharrowbackground.h', 'src/models/recentfilesmodel.h', 'src/models/pathlist.h', 'src/models/storagemodel.h', dbus_adaptor[1], dbus_interface[1]], moc_extra_arguments: ['-I' + qt.get_variable('includedir'), '-I' + qt.get_variable('includedir') + '/QtQml'])
executable('index', index_sources + [dbus_adaptor, dbus_interface] + qt_sources + [index_version], dependencies: [qt, kf6_core, kf6_i18n, kf6_archive, kf6_kio, mauikit, archiver, documents, filebrowsing, terminal, texteditor], include_directories: index_includes, cpp_args: cpp_args, install: true)
install_data('src/org.maui.index.desktop', install_dir: get_option('datadir') / 'applications')
install_data('org.maui.index.appdata.xml', install_dir: get_option('datadir') / 'metainfo')
install_data('src/assets/index.svg', install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps')
install_data('src/data/org.kde.index.notifyrc', install_dir: get_option('datadir') / 'knotifications6')

translation_domain = 'index-fm'
msgfmt = find_program('msgfmt')
po_files = run_command('find', 'po', '-mindepth', '2', '-maxdepth', '2', '-type', 'f', '-name', translation_domain + '.po', check: true).stdout().strip().split('\n')
foreach po_file : po_files
    if po_file != ''
        locale = po_file.split('/')[1]
        custom_target(
            'translation-' + locale,
            input: po_file,
            output: locale / (translation_domain + '.mo'),
            command: [msgfmt, '--check', '-o', '@OUTPUT@', '@INPUT@'],
            install: true,
            install_dir: get_option('localedir') / locale / 'LC_MESSAGES',
            install_tag: 'i18n')
    endif
endforeach
