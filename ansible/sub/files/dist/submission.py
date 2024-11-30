#!/usr/bin/python3

import os
import socket
import time

import configargparse


def main():
    parser = configargparse.ArgumentParser(description='Team Submission')
    parser.add_argument('--ip', type=str, help='Server IP address', env_var='CTF_SUB_IP')
    parser.add_argument('--port', type=int, help='Server port number', env_var='CTF_SUB_PORT')
    parser.add_argument('--path', type=str, help='Path to hot folder', env_var='CTF_HOTFOLDER_PATH')

    # Load argument values from environment file
    env_file = os.getenv('/etc/ctf-team-submission/submission.env')
    if env_file:
        parser.add_argument(env_file)

    args = parser.parse_args()

    # Call the read_hot_folder function with the parsed arguments
    while True:
        read_hot_folder(args.path, args.ip, args.port)
        time.sleep(10)

    return os.EX_OK


def submit_flag(flag, ip, port):
    try:
        # Create a TCP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        # Connect to the server
        sock.connect((ip, port))

        # Receive welcome message from the server
        welcome_msg = sock.recv(1024).decode()
        print(welcome_msg)

        # Send the flag
        sock.sendall(flag.encode() + b'\n')

        # Receive response from the server
        response = sock.recv(1024).decode()
        print(response)

        # Close the socket
        sock.close()

    except Exception as e:
        print(f"An error occurred: {str(e)}")


def read_hot_folder(folder_path, ip, port):
    try:
        # Get the list of files in the folder
        files = os.listdir(folder_path)

        # Filter files with .flag extension
        flag_files = [file for file in files if file.endswith('.flag')]

        # Call submit_flag with each line in the file as flag, ip, and port
        for file in flag_files:
            file_path = os.path.join(folder_path, file)
            with open(file_path, 'r') as f:
                for line in f:
                    submit_flag(line.strip(), ip, port)

            # Remove the file after submitting all lines
            os.remove(file_path)

    except Exception as e:
        print(f"An error occurred: {str(e)}")
