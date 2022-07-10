/**
 * This class is responsible to provide all the util helper methods for the payment operations.
 * 
 */
public with sharing class Util {

	private static String licencekey = '2J<4QXFbws4Kh|J2';
	/**
	 * This method generatess a payment url for dynamically.
	 */
	public static String generateURLParameters( Map<String, Object> parameters) {

		String payload = '';
		for (String key : parameters.keySet()) {
            if(parameters.get(key) != null){
				// Check for string value
				if (parameters.get(key) instanceof String) {
					payload += (EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(
						String.valueOf(parameters.get(key)), 'UTF-8') + '&'
					);
				}
        	}
			// Check for map nested value
			if (parameters.get(key) instanceof Map<String, Object>) {

				// Create sub options handle
				Map<String, Object> subOptions = (Map<String, Object>)parameters.get(key);

				// Loop through sub options
				for (String subKey : subOptions.keySet()) {

					// Check for map nested, nested value
					if (subOptions.get(subKey) instanceof Map<String, Object>) {

						// Create sub, sub options handle
						Map<String, Object> subSubOptions = (Map<String, Object>)subOptions.get(subKey);

						// Loop through sub, sub options
						for (String subSubKey : subSubOptions.keySet()) {
							payload += (
								EncodingUtil.urlEncode(key + '[' + subKey + ']' + '[' + subSubKey + ']', 'UTF-8') +
								'=' +
								EncodingUtil.urlEncode(String.valueOf(subSubOptions.get(subSubKey)), 'UTF-8') +
								'&'
							);
						}						
					}

					// Check for string nested value
					if (subOptions.get(subKey) instanceof String) {
						payload += (
							EncodingUtil.urlEncode(key + '[' + subKey + ']', 'UTF-8') +
							'=' +
							EncodingUtil.urlEncode(String.valueOf(subOptions.get(subKey)), 'UTF-8') +
							'&'
						);
					}
				}
			}
			
		}

		// Return payload
		return payload;
	}

	// This method encrypts the payment url based on the encryption key
    public static String encrypt(String encryptionData, String key){

        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', Blob.valueOf(key == null ? licencekey : key), Blob.valueOf(encryptionData)));   
    }

	// This method decrypts the payment url based on the key
    public static String decrypt(String encryptedString, String key){
		System.debug('encryptedString====>' + encryptedString);
		Blob decodestring = EncodingUtil.base64decode(encryptedString);

        return Crypto.decryptWithManagedIV('AES128', Blob.valueOf(key == null ? licencekey : key), decodestring).toString();  
    }


}