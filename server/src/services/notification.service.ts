import firebaseAdmin from "@config/firebase";
import User from "@models/user";
import UserDevice from "@models/userDevice";
import { UserRole, UserStatus } from "@models/user";
import { RequestType, RequestTypeLabels, RequestStatusLabels, RequestStatus } from "@models/request";

export default class NotificationService {
    
    private static async executeSend(tokens: string[], title: string, body: string) {
        // Kiểm tra nếu không có token hoặc firebase chưa init thì thoát
        if (!firebaseAdmin || tokens.length === 0) return;

        try {
            await firebaseAdmin.messaging().sendEachForMulticast({
                tokens,
                notification: { title, body },
            });
            console.log(`✅ Đã gửi thông báo thành công đến ${tokens.length} thiết bị.`);
        } catch (error) {
            console.error("❌ Lỗi gửi tin Firebase:", error);
        }
    }

    // Hàm báo cho Admin
    static async notifyAdminNewRequest(userName: string, type: RequestType) {
        const admins = await User.findAll({
            where: { role: [UserRole.ADMIN, UserRole.MANAGER], status: UserStatus.ACTIVE },
            include: [{ model: UserDevice, as: 'devices' }]
        });

        // Sửa lỗi (string | null)[] bằng cách lọc sạch null
        const tokens = admins
            .flatMap((a: any) => a.devices?.map((d: any) => d.fcmToken))
            .filter((t): t is string => typeof t === 'string');

        await this.executeSend(tokens, "🔔 Yêu cầu mới", `Nhân viên ${userName} vừa gửi yêu cầu: ${RequestTypeLabels[type]}`);
    }

    // Hàm báo cho User
    static async notifyUserRequestUpdate(userId: string, type: RequestType, status: RequestStatus) {
        const devices = await UserDevice.findAll({ where: { userId } });
        
        // Sửa lỗi (string | null)[] bằng cách lọc sạch null
        const tokens = devices
            .map(d => d.fcmToken)
            .filter((t): t is string => typeof t === 'string');

        const title = status === RequestStatus.APPROVED ? "✅ Yêu cầu được duyệt" : "❌ Yêu cầu bị từ chối";
        await this.executeSend(tokens, title, `Yêu cầu ${RequestTypeLabels[type]} của bạn đã: ${RequestStatusLabels[status]}`);
    }
}