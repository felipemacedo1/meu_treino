package com.meutreino.common;

import org.springframework.http.HttpStatus;

public final class ApiExceptions {

    private ApiExceptions() {
    }

    public static class ApiException extends RuntimeException {
        private final HttpStatus status;

        public ApiException(HttpStatus status, String message) {
            super(message);
            this.status = status;
        }

        public HttpStatus getStatus() {
            return status;
        }
    }

    public static class NotFoundException extends ApiException {
        public NotFoundException(String message) {
            super(HttpStatus.NOT_FOUND, message);
        }
    }

    public static class BadRequestException extends ApiException {
        public BadRequestException(String message) {
            super(HttpStatus.BAD_REQUEST, message);
        }
    }

    public static class ConflictException extends ApiException {
        public ConflictException(String message) {
            super(HttpStatus.CONFLICT, message);
        }
    }

    public static class UnauthorizedException extends ApiException {
        public UnauthorizedException(String message) {
            super(HttpStatus.UNAUTHORIZED, message);
        }
    }
}
