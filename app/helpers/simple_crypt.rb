# frozen_string_literal: true

# This helper is used to encrypt and decrypt strings using AES-256-ECB algorithm.
module SimpleCrypt
  require 'base64'
  require 'openssl'

  KEY_LENGTH = 32

  def self.ensure_key_length(key)
    key = key.to_s
    key.bytesize == KEY_LENGTH
  end

  def self.encrypt(plain_text, key = ENV.fetch('WEBHOOK_SECRET', nil))
    return unless ensure_key_length(key) && plain_text && plain_text != ':id'

    cipher = OpenSSL::Cipher.new('aes-256-ecb')
    cipher.encrypt
    cipher.key = key
    encrypted = cipher.update(plain_text.to_s) + cipher.final
    # Convert to hexadecimal string to ensure alphanumeric characters
    encrypted.unpack1('H*')
  end

  def self.decrypt(encrypted_text, key = ENV.fetch('WEBHOOK_SECRET', nil))
    return unless ensure_key_length(key) && encrypted_text && encrypted_text != ':id'

    decipher = OpenSSL::Cipher.new('aes-256-ecb')
    decipher.decrypt
    decipher.key = key
    # Convert from hexadecimal string back to binary
    encrypted_binary = [encrypted_text].pack('H*')
    decipher.update(encrypted_binary) + decipher.final
  end
end
