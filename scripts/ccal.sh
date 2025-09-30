#!/bin/bash

cal=/usr/bin/cal
esc=""
year="${esc}[48;5;93m"
month="${esc}[48;5;27m"
week="${esc}[48;5;255m${esc}[38;5;0m"
weekend="${esc}[48;5;11m${esc}[38;5;0m"
day="${esc}[48;5;255m${esc}[38;5;200m"
reset="${esc}[m"

$cal $* | sed -e "s/\\([A-Z][b-z]\\) /${day}\\1 ${reset}/g"                       \
              -e "s/Sa/${day}Sa${reset}/g"                                        \
              -e "s/\\([ 0-9][0-9]\\)\\( [ 0-9][0-9] [ 0-9][0-9] [ 0-9][0-9] [ 0-9][0-9] [ 0-9][0-9] \\)\\([ 0-9][0-9]\\)/${weekend}\\1${week}\\2${weekend}\\3${reset}/g"   \
              -e "s/\\(      January       \\)/${month}\\1${reset}/"              \
              -e "s/\\(      February      \\)/${month}\\1${reset}/"              \
              -e "s/\\(       March        \\)/${month}\\1${reset}/"              \
              -e "s/\\(       April        \\)/${month}\\1${reset}/"              \
              -e "s/\\(        May         \\)/${month}\\1${reset}/"              \
              -e "s/\\(        June        \\)/${month}\\1${reset}/"              \
              -e "s/\\(        July        \\)/${month}\\1${reset}/"              \
              -e "s/\\(       August       \\)/${month}\\1${reset}/"              \
              -e "s/\\(     September      \\)/${month}\\1${reset}/"              \
              -e "s/\\(      October       \\)/${month}\\1${reset}/"              \
              -e "s/\\(      November      \\)/${month}\\1${reset}/"              \
              -e "s/\\(      December      \\)/${month}\\1${reset}/"              \
              -e "s/\\( *[0-9][0-9][0-9][0-9]\\)/${year}\\1                                ${reset}/"
