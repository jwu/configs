local wezterm = require 'wezterm'

local config = wezterm.config_builder()

local is_windows = false
local default_cwd = '~'
local font_size = 16
local tab_font_size = 14
local mod_key = 'CMD'
local mod_key_2 = 'CMD|SHIFT'
local font_en = 'FiraMono Nerd Font'
local font_zh = 'PingFang SC'
local front_end = 'WebGpu'
local ls_colors = nil

if wezterm.target_triple:find('windows') then
  is_windows = true
  default_cwd = os.getenv('USERPROFILE') .. '/bin'
  font_size = 12
  tab_font_size = 10
  mod_key = 'ALT'
  mod_key_2 = 'ALT|SHIFT'
  font_zh = 'Microsoft YaHei'
  front_end = 'OpenGL'
  -- this will help eza/lsd use colors follow by wezterm
  ls_colors = '*~=0;38;2;102;102;102:bd=0;38;2;86;182;194;48;2;51;51;51:ca=0:cd=0;38;2;255;106;193;48;2;51;51;51:di=0;38;2;97;175;239:do=0;38;2;0;0;0;48;2;255;106;193:ex=1;38;2;224;108;117:fi=0:ln=0;38;2;255;106;193:mh=0:mi=0;38;2;0;0;0;48;2;224;108;117:no=0:or=0;38;2;0;0;0;48;2;224;108;117:ow=0:pi=0;38;2;0;0;0;48;2;97;175;239:rs=0:sg=0:so=0;38;2;0;0;0;48;2;255;106;193:st=0:su=0:tw=0:*.1=0;38;2;229;192;123:*.a=1;38;2;224;108;117:*.c=0;38;2;152;195;121:*.d=0;38;2;152;195;121:*.h=0;38;2;152;195;121:*.m=0;38;2;152;195;121:*.o=0;38;2;102;102;102:*.p=0;38;2;152;195;121:*.r=0;38;2;152;195;121:*.t=0;38;2;152;195;121:*.v=0;38;2;152;195;121:*.z=4;38;2;86;182;194:*.7z=4;38;2;86;182;194:*.ai=0;38;2;255;106;193:*.as=0;38;2;152;195;121:*.bc=0;38;2;102;102;102:*.bz=4;38;2;86;182;194:*.cc=0;38;2;152;195;121:*.cp=0;38;2;152;195;121:*.cr=0;38;2;152;195;121:*.cs=0;38;2;152;195;121:*.db=4;38;2;86;182;194:*.di=0;38;2;152;195;121:*.el=0;38;2;152;195;121:*.ex=0;38;2;152;195;121:*.fs=0;38;2;152;195;121:*.go=0;38;2;152;195;121:*.gv=0;38;2;152;195;121:*.gz=4;38;2;86;182;194:*.ha=0;38;2;152;195;121:*.hh=0;38;2;152;195;121:*.hi=0;38;2;102;102;102:*.hs=0;38;2;152;195;121:*.jl=0;38;2;152;195;121:*.js=0;38;2;152;195;121:*.ko=1;38;2;224;108;117:*.kt=0;38;2;152;195;121:*.la=0;38;2;102;102;102:*.ll=0;38;2;152;195;121:*.lo=0;38;2;102;102;102:*.ma=0;38;2;255;106;193:*.mb=0;38;2;255;106;193:*.md=0;38;2;229;192;123:*.mk=0;38;2;152;195;121:*.ml=0;38;2;152;195;121:*.mn=0;38;2;152;195;121:*.nb=0;38;2;152;195;121:*.nu=0;38;2;152;195;121:*.pl=0;38;2;152;195;121:*.pm=0;38;2;152;195;121:*.pp=0;38;2;152;195;121:*.ps=0;38;2;224;108;117:*.py=0;38;2;152;195;121:*.rb=0;38;2;152;195;121:*.rm=0;38;2;255;106;193:*.rs=0;38;2;152;195;121:*.sh=0;38;2;152;195;121:*.so=1;38;2;224;108;117:*.td=0;38;2;152;195;121:*.ts=0;38;2;152;195;121:*.ui=0;38;2;229;192;123:*.vb=0;38;2;152;195;121:*.wv=0;38;2;255;106;193:*.xz=4;38;2;86;182;194:*FAQ=0;38;2;40;44;52;48;2;229;192;123:*.3ds=0;38;2;255;106;193:*.3fr=0;38;2;255;106;193:*.3mf=0;38;2;255;106;193:*.adb=0;38;2;152;195;121:*.ads=0;38;2;152;195;121:*.aif=0;38;2;255;106;193:*.amf=0;38;2;255;106;193:*.ape=0;38;2;255;106;193:*.apk=4;38;2;86;182;194:*.ari=0;38;2;255;106;193:*.arj=4;38;2;86;182;194:*.arw=0;38;2;255;106;193:*.asa=0;38;2;152;195;121:*.asm=0;38;2;152;195;121:*.aux=0;38;2;102;102;102:*.avi=0;38;2;255;106;193:*.awk=0;38;2;152;195;121:*.bag=4;38;2;86;182;194:*.bak=0;38;2;102;102;102:*.bat=1;38;2;224;108;117:*.bay=0;38;2;255;106;193:*.bbl=0;38;2;102;102;102:*.bcf=0;38;2;102;102;102:*.bib=0;38;2;229;192;123:*.bin=4;38;2;86;182;194:*.blg=0;38;2;102;102;102:*.bmp=0;38;2;255;106;193:*.bsh=0;38;2;152;195;121:*.bst=0;38;2;229;192;123:*.bz2=4;38;2;86;182;194:*.c++=0;38;2;152;195;121:*.cap=0;38;2;255;106;193:*.cfg=0;38;2;229;192;123:*.cgi=0;38;2;152;195;121:*.clj=0;38;2;152;195;121:*.com=1;38;2;224;108;117:*.cpp=0;38;2;152;195;121:*.cr2=0;38;2;255;106;193:*.cr3=0;38;2;255;106;193:*.crw=0;38;2;255;106;193:*.css=0;38;2;152;195;121:*.csv=0;38;2;229;192;123:*.csx=0;38;2;152;195;121:*.cxx=0;38;2;152;195;121:*.dae=0;38;2;255;106;193:*.dcr=0;38;2;255;106;193:*.dcs=0;38;2;255;106;193:*.deb=4;38;2;86;182;194:*.def=0;38;2;152;195;121:*.dll=1;38;2;224;108;117:*.dmg=4;38;2;86;182;194:*.dng=0;38;2;255;106;193:*.doc=0;38;2;224;108;117:*.dot=0;38;2;152;195;121:*.dox=0;38;2;152;195;121:*.dpr=0;38;2;152;195;121:*.drf=0;38;2;255;106;193:*.dxf=0;38;2;255;106;193:*.eip=0;38;2;255;106;193:*.elc=0;38;2;152;195;121:*.elm=0;38;2;152;195;121:*.epp=0;38;2;152;195;121:*.eps=0;38;2;255;106;193:*.erf=0;38;2;255;106;193:*.erl=0;38;2;152;195;121:*.exe=1;38;2;224;108;117:*.exr=0;38;2;255;106;193:*.exs=0;38;2;152;195;121:*.fbx=0;38;2;255;106;193:*.fff=0;38;2;255;106;193:*.fls=0;38;2;102;102;102:*.flv=0;38;2;255;106;193:*.fnt=0;38;2;255;106;193:*.fon=0;38;2;255;106;193:*.fsi=0;38;2;152;195;121:*.fsx=0;38;2;152;195;121:*.gif=0;38;2;255;106;193:*.git=0;38;2;102;102;102:*.gpr=0;38;2;255;106;193:*.gvy=0;38;2;152;195;121:*.h++=0;38;2;152;195;121:*.hda=0;38;2;255;106;193:*.hip=0;38;2;255;106;193:*.hpp=0;38;2;152;195;121:*.htc=0;38;2;152;195;121:*.htm=0;38;2;229;192;123:*.hxx=0;38;2;152;195;121:*.ico=0;38;2;255;106;193:*.ics=0;38;2;224;108;117:*.idx=0;38;2;102;102;102:*.igs=0;38;2;255;106;193:*.iiq=0;38;2;255;106;193:*.ilg=0;38;2;102;102;102:*.img=4;38;2;86;182;194:*.inc=0;38;2;152;195;121:*.ind=0;38;2;102;102;102:*.ini=0;38;2;229;192;123:*.inl=0;38;2;152;195;121:*.ino=0;38;2;152;195;121:*.ipp=0;38;2;152;195;121:*.iso=4;38;2;86;182;194:*.jar=4;38;2;86;182;194:*.jpg=0;38;2;255;106;193:*.jsx=0;38;2;152;195;121:*.jxl=0;38;2;255;106;193:*.k25=0;38;2;255;106;193:*.kdc=0;38;2;255;106;193:*.kex=0;38;2;224;108;117:*.kra=0;38;2;255;106;193:*.kts=0;38;2;152;195;121:*.log=0;38;2;102;102;102:*.ltx=0;38;2;152;195;121:*.lua=0;38;2;152;195;121:*.m3u=0;38;2;255;106;193:*.m4a=0;38;2;255;106;193:*.m4v=0;38;2;255;106;193:*.mdc=0;38;2;255;106;193:*.mef=0;38;2;255;106;193:*.mid=0;38;2;255;106;193:*.mir=0;38;2;152;195;121:*.mkv=0;38;2;255;106;193:*.mli=0;38;2;152;195;121:*.mos=0;38;2;255;106;193:*.mov=0;38;2;255;106;193:*.mp3=0;38;2;255;106;193:*.mp4=0;38;2;255;106;193:*.mpg=0;38;2;255;106;193:*.mrw=0;38;2;255;106;193:*.msi=4;38;2;86;182;194:*.mtl=0;38;2;255;106;193:*.nef=0;38;2;255;106;193:*.nim=0;38;2;152;195;121:*.nix=0;38;2;229;192;123:*.nrw=0;38;2;255;106;193:*.obj=0;38;2;255;106;193:*.obm=0;38;2;255;106;193:*.odp=0;38;2;224;108;117:*.ods=0;38;2;224;108;117:*.odt=0;38;2;224;108;117:*.ogg=0;38;2;255;106;193:*.ogv=0;38;2;255;106;193:*.orf=0;38;2;255;106;193:*.org=0;38;2;229;192;123:*.otf=0;38;2;255;106;193:*.otl=0;38;2;255;106;193:*.out=0;38;2;102;102;102:*.pas=0;38;2;152;195;121:*.pbm=0;38;2;255;106;193:*.pcx=0;38;2;255;106;193:*.pdf=0;38;2;224;108;117:*.pef=0;38;2;255;106;193:*.pgm=0;38;2;255;106;193:*.php=0;38;2;152;195;121:*.pid=0;38;2;102;102;102:*.pkg=4;38;2;86;182;194:*.png=0;38;2;255;106;193:*.pod=0;38;2;152;195;121:*.ppm=0;38;2;255;106;193:*.pps=0;38;2;224;108;117:*.ppt=0;38;2;224;108;117:*.pro=0;38;2;152;195;121:*.ps1=0;38;2;152;195;121:*.psd=0;38;2;255;106;193:*.ptx=0;38;2;255;106;193:*.pxn=0;38;2;255;106;193:*.pyc=0;38;2;102;102;102:*.pyd=0;38;2;102;102;102:*.pyo=0;38;2;102;102;102:*.qoi=0;38;2;255;106;193:*.r3d=0;38;2;255;106;193:*.raf=0;38;2;255;106;193:*.rar=4;38;2;86;182;194:*.raw=0;38;2;255;106;193:*.rpm=4;38;2;86;182;194:*.rst=0;38;2;229;192;123:*.rtf=0;38;2;224;108;117:*.rw2=0;38;2;255;106;193:*.rwl=0;38;2;255;106;193:*.rwz=0;38;2;255;106;193:*.sbt=0;38;2;152;195;121:*.sql=0;38;2;152;195;121:*.sr2=0;38;2;255;106;193:*.srf=0;38;2;255;106;193:*.srw=0;38;2;255;106;193:*.stl=0;38;2;255;106;193:*.stp=0;38;2;255;106;193:*.sty=0;38;2;102;102;102:*.svg=0;38;2;255;106;193:*.swf=0;38;2;255;106;193:*.swp=0;38;2;102;102;102:*.sxi=0;38;2;224;108;117:*.sxw=0;38;2;224;108;117:*.tar=4;38;2;86;182;194:*.tbz=4;38;2;86;182;194:*.tcl=0;38;2;152;195;121:*.tex=0;38;2;152;195;121:*.tga=0;38;2;255;106;193:*.tgz=4;38;2;86;182;194:*.tif=0;38;2;255;106;193:*.tml=0;38;2;229;192;123:*.tmp=0;38;2;102;102;102:*.toc=0;38;2;102;102;102:*.tsx=0;38;2;152;195;121:*.ttf=0;38;2;255;106;193:*.txt=0;38;2;229;192;123:*.typ=0;38;2;229;192;123:*.usd=0;38;2;255;106;193:*.vcd=4;38;2;86;182;194:*.vim=0;38;2;152;195;121:*.vob=0;38;2;255;106;193:*.vsh=0;38;2;152;195;121:*.wav=0;38;2;255;106;193:*.wma=0;38;2;255;106;193:*.wmv=0;38;2;255;106;193:*.wrl=0;38;2;255;106;193:*.x3d=0;38;2;255;106;193:*.x3f=0;38;2;255;106;193:*.xlr=0;38;2;224;108;117:*.xls=0;38;2;224;108;117:*.xml=0;38;2;229;192;123:*.xmp=0;38;2;229;192;123:*.xpm=0;38;2;255;106;193:*.xvf=0;38;2;255;106;193:*.yml=0;38;2;229;192;123:*.zig=0;38;2;152;195;121:*.zip=4;38;2;86;182;194:*.zsh=0;38;2;152;195;121:*.zst=4;38;2;86;182;194:*TODO=1:*hgrc=0;38;2;152;195;121:*.avif=0;38;2;255;106;193:*.bash=0;38;2;152;195;121:*.braw=0;38;2;255;106;193:*.conf=0;38;2;229;192;123:*.dart=0;38;2;152;195;121:*.data=0;38;2;255;106;193:*.diff=0;38;2;152;195;121:*.docx=0;38;2;224;108;117:*.epub=0;38;2;224;108;117:*.fish=0;38;2;152;195;121:*.flac=0;38;2;255;106;193:*.h264=0;38;2;255;106;193:*.hack=0;38;2;152;195;121:*.heif=0;38;2;255;106;193:*.hgrc=0;38;2;152;195;121:*.html=0;38;2;229;192;123:*.iges=0;38;2;255;106;193:*.info=0;38;2;229;192;123:*.java=0;38;2;152;195;121:*.jpeg=0;38;2;255;106;193:*.json=0;38;2;229;192;123:*.less=0;38;2;152;195;121:*.lisp=0;38;2;152;195;121:*.lock=0;38;2;102;102;102:*.make=0;38;2;152;195;121:*.mojo=0;38;2;152;195;121:*.mpeg=0;38;2;255;106;193:*.nims=0;38;2;152;195;121:*.opus=0;38;2;255;106;193:*.orig=0;38;2;102;102;102:*.pptx=0;38;2;224;108;117:*.prql=0;38;2;152;195;121:*.psd1=0;38;2;152;195;121:*.psm1=0;38;2;152;195;121:*.purs=0;38;2;152;195;121:*.raku=0;38;2;152;195;121:*.rlib=0;38;2;102;102;102:*.sass=0;38;2;152;195;121:*.scad=0;38;2;152;195;121:*.scss=0;38;2;152;195;121:*.step=0;38;2;255;106;193:*.tbz2=4;38;2;86;182;194:*.tiff=0;38;2;255;106;193:*.toml=0;38;2;229;192;123:*.usda=0;38;2;255;106;193:*.usdc=0;38;2;255;106;193:*.usdz=0;38;2;255;106;193:*.webm=0;38;2;255;106;193:*.webp=0;38;2;255;106;193:*.woff=0;38;2;255;106;193:*.xbps=4;38;2;86;182;194:*.xlsx=0;38;2;224;108;117:*.yaml=0;38;2;229;192;123:*stdin=0;38;2;102;102;102:*v.mod=0;38;2;152;195;121:*.blend=0;38;2;255;106;193:*.cabal=0;38;2;152;195;121:*.cache=0;38;2;102;102;102:*.class=0;38;2;102;102;102:*.cmake=0;38;2;152;195;121:*.ctags=0;38;2;102;102;102:*.dylib=1;38;2;224;108;117:*.dyn_o=0;38;2;102;102;102:*.gcode=0;38;2;152;195;121:*.ipynb=0;38;2;152;195;121:*.mdown=0;38;2;229;192;123:*.patch=0;38;2;152;195;121:*.rmeta=0;38;2;102;102;102:*.scala=0;38;2;152;195;121:*.shtml=0;38;2;229;192;123:*.swift=0;38;2;152;195;121:*.toast=4;38;2;86;182;194:*.woff2=0;38;2;255;106;193:*.xhtml=0;38;2;229;192;123:*Icon\r=0;38;2;102;102;102:*LEGACY=0;38;2;40;44;52;48;2;229;192;123:*NOTICE=0;38;2;40;44;52;48;2;229;192;123:*README=0;38;2;40;44;52;48;2;229;192;123:*go.mod=0;38;2;152;195;121:*go.sum=0;38;2;102;102;102:*passwd=0;38;2;229;192;123:*shadow=0;38;2;229;192;123:*stderr=0;38;2;102;102;102:*stdout=0;38;2;102;102;102:*.bashrc=0;38;2;152;195;121:*.config=0;38;2;229;192;123:*.dyn_hi=0;38;2;102;102;102:*.flake8=0;38;2;152;195;121:*.gradle=0;38;2;152;195;121:*.groovy=0;38;2;152;195;121:*.ignore=0;38;2;152;195;121:*.matlab=0;38;2;152;195;121:*.nimble=0;38;2;152;195;121:*COPYING=0;38;2;153;153;153:*INSTALL=0;38;2;40;44;52;48;2;229;192;123:*LICENCE=0;38;2;153;153;153:*LICENSE=0;38;2;153;153;153:*TODO.md=1:*VERSION=0;38;2;40;44;52;48;2;229;192;123:*.alembic=0;38;2;255;106;193:*.desktop=0;38;2;229;192;123:*.gemspec=0;38;2;152;195;121:*.mailmap=0;38;2;152;195;121:*Doxyfile=0;38;2;152;195;121:*Makefile=0;38;2;152;195;121:*TODO.txt=1:*setup.py=0;38;2;152;195;121:*.DS_Store=0;38;2;102;102;102:*.cmake.in=0;38;2;152;195;121:*.fdignore=0;38;2;152;195;121:*.kdevelop=0;38;2;152;195;121:*.markdown=0;38;2;229;192;123:*.rgignore=0;38;2;152;195;121:*.tfignore=0;38;2;152;195;121:*CHANGELOG=0;38;2;40;44;52;48;2;229;192;123:*COPYRIGHT=0;38;2;153;153;153:*README.md=0;38;2;40;44;52;48;2;229;192;123:*bun.lockb=0;38;2;102;102;102:*configure=0;38;2;152;195;121:*.gitconfig=0;38;2;152;195;121:*.gitignore=0;38;2;152;195;121:*.localized=0;38;2;102;102;102:*.scons_opt=0;38;2;102;102;102:*.timestamp=0;38;2;102;102;102:*CODEOWNERS=0;38;2;152;195;121:*Dockerfile=0;38;2;229;192;123:*INSTALL.md=0;38;2;40;44;52;48;2;229;192;123:*README.txt=0;38;2;40;44;52;48;2;229;192;123:*SConscript=0;38;2;152;195;121:*SConstruct=0;38;2;152;195;121:*.cirrus.yml=0;38;2;152;195;121:*.gitmodules=0;38;2;152;195;121:*.synctex.gz=0;38;2;102;102;102:*.travis.yml=0;38;2;152;195;121:*INSTALL.txt=0;38;2;40;44;52;48;2;229;192;123:*LICENSE-MIT=0;38;2;153;153;153:*MANIFEST.in=0;38;2;152;195;121:*Makefile.am=0;38;2;152;195;121:*Makefile.in=0;38;2;102;102;102:*.applescript=0;38;2;152;195;121:*.fdb_latexmk=0;38;2;102;102;102:*.webmanifest=0;38;2;229;192;123:*CHANGELOG.md=0;38;2;40;44;52;48;2;229;192;123:*CONTRIBUTING=0;38;2;40;44;52;48;2;229;192;123:*CONTRIBUTORS=0;38;2;40;44;52;48;2;229;192;123:*appveyor.yml=0;38;2;152;195;121:*configure.ac=0;38;2;152;195;121:*.bash_profile=0;38;2;152;195;121:*.clang-format=0;38;2;152;195;121:*.editorconfig=0;38;2;152;195;121:*CHANGELOG.txt=0;38;2;40;44;52;48;2;229;192;123:*.gitattributes=0;38;2;152;195;121:*.gitlab-ci.yml=0;38;2;152;195;121:*CMakeCache.txt=0;38;2;102;102;102:*CMakeLists.txt=0;38;2;152;195;121:*LICENSE-APACHE=0;38;2;153;153;153:*pyproject.toml=0;38;2;152;195;121:*CODE_OF_CONDUCT=0;38;2;40;44;52;48;2;229;192;123:*CONTRIBUTING.md=0;38;2;40;44;52;48;2;229;192;123:*CONTRIBUTORS.md=0;38;2;40;44;52;48;2;229;192;123:*.sconsign.dblite=0;38;2;102;102;102:*CONTRIBUTING.txt=0;38;2;40;44;52;48;2;229;192;123:*CONTRIBUTORS.txt=0;38;2;40;44;52;48;2;229;192;123:*requirements.txt=0;38;2;152;195;121:*package-lock.json=0;38;2;102;102;102:*CODE_OF_CONDUCT.md=0;38;2;40;44;52;48;2;229;192;123:*.CFUserTextEncoding=0;38;2;102;102;102:*CODE_OF_CONDUCT.txt=0;38;2;40;44;52;48;2;229;192;123:*azure-pipelines.yml=0;38;2;152;195;121'
end

config.default_cwd = default_cwd

config.set_environment_variables = {
  TERM = 'wezterm',
}

-- NOTE: in clink.lua, we do the same thing, cause alacritty need it
if ls_colors then
  config.set_environment_variables.LS_COLORS = ls_colors
end

----------------------------------------------------------------------
-- Appearance
----------------------------------------------------------------------

-- Window
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS|MACOS_FORCE_ENABLE_SHADOW'
config.integrated_title_button_alignment = 'Right'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
-- config.integrated_title_button_style = 'Windows'
config.window_background_opacity = 0.95
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.adjust_window_size_when_changing_font_size = false
-- config.initial_cols = 80
-- config.initial_rows = 40

-- Tab Bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 16 -- ignore when use fancy_tab_bar
config.enable_scroll_bar = false

-- Colors
config.color_scheme = 'OneHalfDark'
config.window_frame = {
  font = wezterm.font { family = 'Roboto', weight = 'Bold' },
  font_size = tab_font_size,
  active_titlebar_bg = '#282c34',
  inactive_titlebar_bg = '#282c34',
}
config.colors = {
  tab_bar = {
    -- active tab
    active_tab = {
      bg_color = '#c678dd',
      fg_color = '#282c34',
      intensity = 'Bold',
      underline = 'None',
      italic = false,
      strikethrough = false,
    },

    -- inactive tab
    inactive_tab = {
      bg_color = '#282c34', -- '#1b1032',
      fg_color = '#606060',
    },
    inactive_tab_hover = {
      bg_color = '#3e2e53',
      fg_color = '#808080',
    },

    -- new tab
    new_tab = {
      bg_color = '#606060',
      fg_color = '#282c34',
    },
    new_tab_hover = {
      bg_color = '#c678dd',
      fg_color = '#282c34',
    },

    -- separator
    inactive_tab_edge = '#606060',
  },

  -- NOTE: We only change Color 8 (use neovim OneDark Comment Color),
  -- others keep OneHalfDark's colors
  brights = {
    '#5c6370', -- Color 8:  Bright Black
    '#e06c75', -- Color 9:  Bright Red
    '#98c379', -- Color 10: Bright Green
    '#e5c07b', -- Color 11: Bright Yellow
    '#61afef', -- Color 12: Bright Blue
    '#c678dd', -- Color 13: Bright Magenta
    '#56b6c2', -- Color 14: Bright Cyan
    '#dcdfe4', -- Color 15: Bright White
  },

  -- split
  split = '#606060',
}
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.7,
}

local function get_process_name(pane)
  local process_name = pane.foreground_process_name
  if not process_name then return '' end

  local name = process_name:match('([^/\\]+)$')
  if not name then name = process_name end

  name = name:gsub('%.[eE][xX][eE]$', '')

  return name
end

-- Helper function to abbreviate path with ~ for home directory
local function abbreviate_path(path)
  -- Windows home: C:\Users\username
  path = path:gsub('^[A-Z]:\\Users\\[^\\]+', '~')

  -- Cygwin/MSYS home: /c/Users/username
  path = path:gsub('^/c/Users/[^/]+', '~')

  -- Unix/Linux home: /home/username or /Users/username
  path = path:gsub('^/home/[^/]+', '~')
  path = path:gsub('^/Users/[^/]+', '~')

  return path
end

-- Helper function to extract path from title string
local function extract_path_from_title(title)
  if not title or title == '' then
    return nil
  end

  -- Format 1: user@host:/path or SSH connection
  local path = title:match('[:%s]*([~]?/[a-zA-Z0-9_/-]+)$')
  if path then
    return path
  end

  -- Format 2: PowerShell - C:\path or C:\path
  local win_path = title:match('([A-Z]:\\[^\r\n\t ]+)$')
  if win_path then
    return win_path
  end

  -- Format 3: /c/Users/user or /home/user
  local unix_path = title:match('^(/[a-zA-Z0-9_/-]+)$')
  if unix_path then
    return unix_path
  end

  -- Format 4: WSL or other domain names (e.g., "WSL:Ubuntu")
  -- In this case there's no path, return nil
  return nil
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local title_text = pane.title or ''
  local title = ''

  -- SSH detection and styling
  local is_ssh = false
  local process_name = get_process_name(pane)
  if process_name == 'ssh' then
    is_ssh = true
  end

  -- if ssh detected, change path by pane.title
  if is_ssh then
    -- No shell integration, extract path from pane.title
    local extracted_path = extract_path_from_title(title_text)

    if extracted_path then
      title = abbreviate_path(extracted_path)
    elseif title_text == 'wezterm' or title_text == 'bash' or title_text == "zsh" or title_text == "cmd.exe" or title_text == "powershell" then
      -- If title is the default process name, show ~
      title = '~'
    end
  else
    -- Try to get path from current_working_dir otherwise
    local cwd_uri = pane.current_working_dir
    if cwd_uri then

      -- Shell integration is available, use cwd directly
      local cwd = cwd_uri.file_path or ''

      -- Convert to appropriate path format
      if is_windows then
        -- On Windows, cwd might be in URL format or local path
        cwd = cwd:gsub('^/([A-Za-z]:)', '%1')
        cwd = cwd:gsub('/', '\\')
      end
      title = abbreviate_path(cwd)
    end
  end

  -- Other cases (e.g., WSL:Ubuntu), use title directly
  if not title or title == '' then
    title = title_text
  end

  -- formatted title with SSH
  if is_ssh then
    title = 'ssh: ' .. title

    -- NOTE: return SSH active tab with red color
    if tab.is_active then
      return {
        { Background = { Color = '#e06c75' } },
        { Text = ' ' .. title .. ' ' },
      }
    end
  end

  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

----------------------------------------------------------------------
-- Rendering
----------------------------------------------------------------------

config.front_end = front_end
config.bold_brightens_ansi_colors = true
config.max_fps = 60

----------------------------------------------------------------------
-- General
----------------------------------------------------------------------

config.automatically_reload_config = true
config.window_close_confirmation = 'NeverPrompt'

----------------------------------------------------------------------
-- Font
----------------------------------------------------------------------

config.font_size = font_size
config.freetype_load_target = 'Light'
config.freetype_render_target = 'Light'
config.freetype_load_flags = 'NO_HINTING'

config.font = wezterm.font_with_fallback({
  {
    family = font_en,
    weight = 'Medium',
  },
  {
    family = font_zh,
    weight = 'Medium'
  },
})

config.font_rules = {
  {
    intensity = 'Bold',
    font = wezterm.font({
      family = font_en,
      weight = 'Bold',
    }),
  },
  {
    italic = true,
    font = wezterm.font({
      family = font_en,
      style = 'Italic',
    }),
  },
  {
    italic = true,
    intensity = 'Bold',
    font = wezterm.font({
      family = font_en,
      weight = 'Bold',
      style = 'Italic',
    }),
  },
}

----------------------------------------------------------------------
-- Cursor
----------------------------------------------------------------------

config.cursor_blink_rate = 750
config.cursor_blink_ease_in = 'EaseOut'
config.cursor_blink_ease_out = 'EaseOut'
config.default_cursor_style = 'BlinkingBlock'

----------------------------------------------------------------------
-- Scroll
----------------------------------------------------------------------

config.scrollback_lines = 10000
config.mouse_wheel_scrolls_tabs = false

----------------------------------------------------------------------
-- Mouse
----------------------------------------------------------------------

config.hide_mouse_cursor_when_typing = false

----------------------------------------------------------------------
-- Selection
----------------------------------------------------------------------

config.selection_word_boundary = '{}[]()"\'`.,;:'

----------------------------------------------------------------------
-- Bell
----------------------------------------------------------------------

config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseOut',
  fade_out_function = 'EaseOut',
  fade_in_duration_ms = 0,
  fade_out_duration_ms = 0,
}

----------------------------------------------------------------------
-- Key Bindings
----------------------------------------------------------------------

config.keys = {
  -- new & close
  -- {
  --   key = 't',
  --   mods = mod_key,
  --   action = wezterm.action.SpawnTab('CurrentPaneDomain'),
  -- },
  {
    key = 'n',
    mods = mod_key,
    action = wezterm.action.SpawnWindow,
  },
  {
    key = 'w',
    mods = mod_key,
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  -- {
  --   key = 'Enter',
  --   mods = 'CTRL',
  --   action = wezterm.action.TogglePaneZoomState,
  -- },

  -- active pane
  {
    key = 'LeftArrow',
    mods = mod_key_2,
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = mod_key_2,
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = mod_key_2,
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = mod_key_2,
    action = wezterm.action.ActivatePaneDirection 'Down',
  },

  -- split pane
  {
    key = 'd',
    mods = mod_key,
    action = wezterm.action.SplitPane {
      direction = 'Right',
      size = { Percent = 50 },
    },
  },
  {
    key = 'd',
    mods = mod_key_2,
    action = wezterm.action.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },
  -- {
  --   key = 'LeftArrow',
  --   mods = mod_key_2,
  --   action = wezterm.action.SplitPane {
  --     direction = 'Left',
  --     size = { Percent = 50 },
  --   },
  -- },
  -- {
  --   key = 'RightArrow',
  --   mods = mod_key_2,
  --   action = wezterm.action.SplitPane {
  --     direction = 'Right',
  --     size = { Percent = 50 },
  --   },
  -- },
  -- {
  --   key = 'UpArrow',
  --   mods = mod_key_2,
  --   action = wezterm.action.SplitPane {
  --     direction = 'Up',
  --     size = { Percent = 50 },
  --   },
  -- },
  -- {
  --   key = 'DownArrow',
  --   mods = mod_key_2,
  --   action = wezterm.action.SplitPane {
  --     direction = 'Down',
  --     size = { Percent = 50 },
  --   },
  -- },

  -- command
  {
    key = 'p',
    mods = mod_key_2,
    action = wezterm.action.ActivateCommandPalette
  },
}

----------------------------------------------------------------------
-- Mouse Bindings
----------------------------------------------------------------------

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = mod_key,
    action = wezterm.action.OpenLinkAtMouseCursor
  },
}

----------------------------------------------------------------------

return config
