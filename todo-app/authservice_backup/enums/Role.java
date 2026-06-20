package vti.dtn.thenvkhoadev.authservice.enums;

public enum Role {
    ADMIN,
    USER,
    MANAGER;

    public static Role toEnum(String value) {
        for(Role role : Role.values()) {
            if(role.toString().equalsIgnoreCase(value)) return role;
        }
        return null;
    }
}
