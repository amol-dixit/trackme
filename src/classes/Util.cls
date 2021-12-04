public with sharing class Util {
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

			if (parameters.get(key) instanceof List<Map<String, Object>>) {
				// Create sub options handle
				List<Map<String, Object>> subOptionsList = (List<Map<String, Object>>)parameters.get(key);
				system.debug('subOptionsList===>' + subOptionsList);

				

				for(Map<String, Object> subOptions : subOptionsList){
				//Map<String, Object>> subOptions = (Map<String, Object>)parameters.get(key);
				system.debug('subOptions===>' + subOptions);

				
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
        }
		}

		// Return payload
		return payload;
	}

    public static String encrypt(String encryptionData, String key){

        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', Blob.valueOf(key == null ? 'trackmepaymentss' : key), Blob.valueOf(encryptionData)));   
    }

    public static String decrypt(String encryptedString, String key){
		System.debug('encryptedString====>' + encryptedString);
		Blob decodestring = EncodingUtil.base64decode(encryptedString);

        return Crypto.decryptWithManagedIV('AES128', Blob.valueOf(key == null ? 'trackmepaymentss' : key), decodestring).toString();  
    }


}