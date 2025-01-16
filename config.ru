# frozen_string_literal: true

# Force encoding to UTF-8 incase we run across an ASCII-8bit
Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

require './app'

run App
