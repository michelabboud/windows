#!/usr/bin/env bash
set -Eeuo pipefail

: "${KEY:=""}"
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${EDITION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"

parseVersion() {
  # Windows 11 x64 Enterprise Evaluation is the only supported version
  VERSION="win11x64-enterprise-eval"
  return 0
}

getLanguage() {

  local id="$1"
  local ret="$2"
  local lang=""
  local desc=""
  local short=""
  local culture=""

  case "${id,,}" in
    "ar" | "ar-"* )
      short="ar"
      lang="Arabic"
      desc="$lang"
      culture="ar-SA" ;;
    "bg" | "bg-"* )
      short="bg"
      lang="Bulgarian"
      desc="$lang"
      culture="bg-BG" ;;
    "cs" | "cs-"* | "cz" | "cz-"* )
      short="cs"
      lang="Czech"
      desc="$lang"
      culture="cs-CZ" ;;
    "da" | "da-"* | "dk" | "dk-"* )
      short="da"
      lang="Danish"
      desc="$lang"
      culture="da-DK" ;;
    "de" | "de-"* )
      short="de"
      lang="German"
      desc="$lang"
      culture="de-DE" ;;
    "el" | "el-"* | "gr" | "gr-"* )
      short="el"
      lang="Greek"
      desc="$lang"
      culture="el-GR" ;;
    "gb" | "en-gb" )
      short="en-gb"
      lang="English International"
      desc="English"
      culture="en-GB" ;;
    "en" | "en-"* )
      short="en"
      lang="English"
      desc="English"
      culture="en-US" ;;
    "mx" | "es-mx" )
      short="mx"
      lang="Spanish (Mexico)"
      desc="Spanish"
      culture="es-MX" ;;
    "es" | "es-"* )
      short="es"
      lang="Spanish"
      desc="$lang"
      culture="es-ES" ;;
    "et" | "et-"* )
      short="et"
      lang="Estonian"
      desc="$lang"
      culture="et-EE" ;;
    "fi" | "fi-"* )
      short="fi"
      lang="Finnish"
      desc="$lang"
      culture="fi-FI" ;;
    "ca" | "fr-ca" )
      short="ca"
      lang="French Canadian"
      desc="French"
      culture="fr-CA" ;;
    "fr" | "fr-"* )
      short="fr"
      lang="French"
      desc="$lang"
      culture="fr-FR" ;;
    "he" | "he-"* | "il" | "il-"* )
      short="he"
      lang="Hebrew"
      desc="$lang"
      culture="he-IL" ;;
    "hr" | "hr-"* | "cr" | "cr-"* )
      short="hr"
      lang="Croatian"
      desc="$lang"
      culture="hr-HR" ;;
    "hu" | "hu-"* )
      short="hu"
      lang="Hungarian"
      desc="$lang"
      culture="hu-HU" ;;
    "it" | "it-"* )
      short="it"
      lang="Italian"
      desc="$lang"
      culture="it-IT" ;;
    "ja" | "ja-"* | "jp" | "jp-"* )
      short="ja"
      lang="Japanese"
      desc="$lang"
      culture="ja-JP" ;;
    "ko" | "ko-"* | "kr" | "kr-"* )
      short="ko"
      lang="Korean"
      desc="$lang"
      culture="ko-KR" ;;
    "lt" | "lt-"* )
      short="lt"
      lang="Lithuanian"
      desc="$lang"
      culture="lt-LT" ;;
    "lv" | "lv-"* )
      short="lv"
      lang="Latvian"
      desc="$lang"
      culture="lv-LV" ;;
    "nb" | "nb-"* |"nn" | "nn-"* | "no" | "no-"* )
      short="no"
      lang="Norwegian"
      desc="$lang"
      culture="nb-NO" ;;
    "nl" | "nl-"* )
      short="nl"
      lang="Dutch"
      desc="$lang"
      culture="nl-NL" ;;
    "pl" | "pl-"* )
      short="pl"
      lang="Polish"
      desc="$lang"
      culture="pl-PL" ;;
    "br" | "pt-br" )
      short="pt"
      lang="Brazilian Portuguese"
      desc="Portuguese"
      culture="pt-BR" ;;
    "pt" | "pt-"* )
      short="pp"
      lang="Portuguese"
      desc="$lang"
      culture="pt-BR" ;;
    "ro" | "ro-"* )
      short="ro"
      lang="Romanian"
      desc="$lang"
      culture="ro-RO" ;;
    "ru" | "ru-"* )
      short="ru"
      lang="Russian"
      desc="$lang"
      culture="ru-RU" ;;
    "sk" | "sk-"* )
      short="sk"
      lang="Slovak"
      desc="$lang"
      culture="sk-SK" ;;
    "sl" | "sl-"* | "si" | "si-"* )
      short="sl"
      lang="Slovenian"
      desc="$lang"
      culture="sl-SI" ;;
    "sr" | "sr-"* )
      short="sr"
      lang="Serbian Latin"
      desc="Serbian"
      culture="sr-Latn-RS" ;;
    "sv" | "sv-"* | "se" | "se-"* )
      short="sv"
      lang="Swedish"
      desc="$lang"
      culture="sv-SE" ;;
    "th" | "th-"* )
      short="th"
      lang="Thai"
      desc="$lang"
      culture="th-TH" ;;
    "tr" | "tr-"* )
      short="tr"
      lang="Turkish"
      desc="$lang"
      culture="tr-TR" ;;
    "ua" | "ua-"* | "uk" | "uk-"* )
      short="uk"
      lang="Ukrainian"
      desc="$lang"
      culture="uk-UA" ;;
    "hk" | "zh-hk" | "cn-hk" )
      short="hk"
      lang="Chinese (Traditional)"
      desc="Chinese HK"
      culture="zh-TW" ;;
    "tw" | "zh-tw" | "cn-tw" )
      short="tw"
      lang="Chinese (Traditional)"
      desc="Chinese TW"
      culture="zh-TW" ;;
    "zh" | "zh-"* | "cn" | "cn-"* )
      short="cn"
      lang="Chinese (Simplified)"
      desc="Chinese"
      culture="zh-CN" ;;
  esac

  case "${ret,,}" in
    "desc" ) echo "$desc" ;;
    "name" ) echo "$lang" ;;
    "code" ) echo "$short" ;;
    "culture" ) echo "$culture" ;;
    *) echo "$desc";;
  esac

  return 0
}

parseLanguage() {

  REGION="${REGION//_/-/}"
  KEYBOARD="${KEYBOARD//_/-/}"
  LANGUAGE="${LANGUAGE//_/-/}"

  [ -z "$LANGUAGE" ] && LANGUAGE="en"

  case "${LANGUAGE,,}" in
    "arabic" | "arab" ) LANGUAGE="ar" ;;
    "bulgarian" | "bu" ) LANGUAGE="bg" ;;
    "chinese" | "cn" ) LANGUAGE="zh" ;;
    "croatian" | "cr" | "hrvatski" ) LANGUAGE="hr" ;;
    "czech" | "cz" | "cesky" ) LANGUAGE="cs" ;;
    "danish" | "dk" | "danske" ) LANGUAGE="da" ;;
    "dutch" | "nederlands" ) LANGUAGE="nl" ;;
    "english" | "gb" | "british" ) LANGUAGE="en" ;;
    "estonian" | "eesti" ) LANGUAGE="et" ;;
    "finnish" | "suomi" ) LANGUAGE="fi" ;;
    "french" | "français" | "francais" ) LANGUAGE="fr" ;;
    "german" | "deutsch" ) LANGUAGE="de" ;;
    "greek" | "gr" ) LANGUAGE="el" ;;
    "hebrew" | "il" ) LANGUAGE="he" ;;
    "hungarian" | "magyar" ) LANGUAGE="hu" ;;
    "italian" | "italiano" ) LANGUAGE="it" ;;
    "japanese" | "jp" ) LANGUAGE="ja" ;;
    "korean" | "kr" ) LANGUAGE="ko" ;;
    "latvian" | "latvijas" ) LANGUAGE="lv" ;;
    "lithuanian" | "lietuvos" ) LANGUAGE="lt" ;;
    "norwegian" | "no" | "nb" | "norsk" ) LANGUAGE="nn" ;;
    "polish" | "polski" ) LANGUAGE="pl" ;;
    "portuguese" | "pt" | "br" ) LANGUAGE="pt-br" ;;
    "português" | "portugues" ) LANGUAGE="pt-br" ;;
    "romanian" | "română" | "romana" ) LANGUAGE="ro" ;;
    "russian" | "ruski" ) LANGUAGE="ru" ;;
    "serbian" | "serbian latin" ) LANGUAGE="sr" ;;
    "slovak" | "slovenský" | "slovensky" ) LANGUAGE="sk" ;;
    "slovenian" | "si" | "slovenski" ) LANGUAGE="sl" ;;
    "spanish" | "espanol" | "español" ) LANGUAGE="es" ;;
    "swedish" | "se" | "svenska" ) LANGUAGE="sv" ;;
    "turkish" | "türk" | "turk" ) LANGUAGE="tr" ;;
    "thai" ) LANGUAGE="th" ;;
    "ukrainian" | "ua" ) LANGUAGE="uk" ;;
  esac

  local culture
  culture=$(getLanguage "$LANGUAGE" "culture")
  [ -n "$culture" ] && return 0

  error "Invalid LANGUAGE specified, value \"$LANGUAGE\" is not recognized!"
  return 1
}

printVersion() {
  echo "Windows 11"
  return 0
}

printEdition() {

  local id="$1"
  local desc="$2"

  echo "Windows 11 Enterprise (Evaluation)"
  return 0
}

fromName() {
  echo "win11x64"
  return 0
}

getVersion() {
  echo "win11x64-enterprise-eval"
  return 0
}

addFolder() {

  local src="$1"
  local folder="/oem"

  [ ! -d "$folder" ] && folder="/OEM"
  [ ! -d "$folder" ] && folder="$STORAGE/oem"
  [ ! -d "$folder" ] && folder="$STORAGE/OEM"
  [ ! -d "$folder" ] && return 0

  local msg="Adding OEM folder to image..."
  info "$msg" && html "$msg"

  local dest="$src/\$OEM\$/\$1/OEM"
  mkdir -p "$dest" || return 1
  cp -Lr "$folder/." "$dest" || return 1

  local file
  file=$(find "$dest" -maxdepth 1 -type f -iname install.bat  -print -quit)
  [ -f "$file" ] && unix2dos -q "$file"

  return 0
}

return 0
